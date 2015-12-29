// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

final internal class NSConcreteValue : NSObject, NSCopying, NSSecureCoding, NSCoding {
    enum SpecialFlags : Int {
        case NotSpecialType = 0
    }
    
    struct TypeInfoHeader : Equatable {
        let size : Int
        let name : String

        init(size: Int, withName name: String) {
            self.size = size
            self.name = name
        }
    }

    typealias TypeInfo = ManagedBuffer<TypeInfoHeader, Int8>
    
    static var _cachedTypeInfo = Dictionary<String, TypeInfo>()
    
    var _specialFlags : SpecialFlags = .NotSpecialType
    var _typeInfo : TypeInfo
    var _value : UnsafeMutablePointer<UInt8>
    
    static func createTypeInfoNonSpecial(spec: String, objCType typep: UnsafePointer<Int8>) -> TypeInfo? {
        var size: Int = 0
        var align: Int = 0
        var count : Int = 0
        let extraBytes : Int = spec.length + 1 // extra bytes after TypeInfoHeader
        
        var type = _NSSimpleObjCType(spec)
        guard type != nil else {
            print("NSConcreteValue.createTypeInfoNonSpecial: unsupported type encoding spec '\(spec)'")
            return nil
        }
        
        if type == .StructBegin {
            fatalError("NSConcreteValue.createTypeInfoNonSpecial: cannot encode structs")
        } else if type == .ArrayBegin {
            let scanner = NSScanner(string: spec)
            
            scanner.scanLocation = 1
            
            guard scanner.scanInteger(&count) && count > 0 else {
                print("NSKeyedUnarchiver.decodeValueOfObjCType: array count is missing or zero")
                return nil
            }
            
            guard let elementType = _NSSimpleObjCType(scanner.scanUpToString(String(_NSSimpleObjCType.ArrayEnd))) else {
                print("NSKeyedUnarchiver.decodeValueOfObjCType: array type is missing")
                return nil
            }
            
            guard _NSGetSizeAndAlignment(elementType, &size, &align) else {
                print("NSConcreteValue.createTypeInfoNonSpecial: unsupported type encoding spec '\(spec)'")
                return nil
            }
            
            type = elementType
        }

        guard _NSGetSizeAndAlignment(type!, &size, &align) else {
            print("NSConcreteValue.createTypeInfoNonSpecial: unsupported type encoding spec '\(spec)'")
            return nil
        }

        let typeInfo = TypeInfo.create(extraBytes, initialValue: {(buffer: ManagedProtoBuffer<TypeInfoHeader, Int8>) -> TypeInfoHeader in
            buffer.withUnsafeMutablePointers({(value: UnsafeMutablePointer<NSConcreteValue.TypeInfoHeader>,
                                               typedata: UnsafeMutablePointer<Int8>) -> TypeInfoHeader in
                typedata.initializeFrom(unsafeBitCast(typep, UnsafeMutablePointer<Int8>.self), count: extraBytes)
                if count != 0 {
                    size *= count // is an array
                }
                return TypeInfoHeader(size: size, withName: spec)
            })
        })
        
        return typeInfo
    }
 
    static func createTypeInfo(name: String, objCType typep: UnsafePointer<Int8>) -> TypeInfo? {
        return createTypeInfoNonSpecial(name, objCType: typep)
    }
    
    required init(bytes value: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        let spec = String.fromCString(type)!

        var typeInfo = NSConcreteValue._cachedTypeInfo[spec]
        if typeInfo == nil {
            typeInfo = NSConcreteValue.createTypeInfo(spec, objCType: type)
            guard typeInfo != nil else {
                fatalError("NSConcreteValue.init: failed to initialize from type encoding spec '\(spec)'")
            }
            NSConcreteValue._cachedTypeInfo[spec] = typeInfo
        }

        self._typeInfo = typeInfo!
        self._value = UnsafeMutablePointer<UInt8>.alloc(self._typeInfo.value.size)
        if value != nil {
            self._value.initializeFrom(unsafeBitCast(value, UnsafeMutablePointer<UInt8>.self), count: self._typeInfo.value.size)
        }
        
        super.init()
    }
 
    deinit {
        self._value.destroy(self._size)
        self._value.dealloc(self._size)
    }
    
    func getValue(value: UnsafeMutablePointer<Void>) {
        UnsafeMutablePointer<UInt8>(value).moveInitializeFrom(self._value, count: self._size)
    }
    
    var objCType : UnsafePointer<Int8> {
        get {
            return self._typeInfo.withUnsafeMutablePointerToElements { (typep: UnsafeMutablePointer<Int8>) -> UnsafePointer<Int8> in
                return unsafeBitCast(typep, UnsafePointer<Int8>.self)
            }
        }
    }
    
    override var classForKeyedArchiver: AnyClass? {
        return NSValue.self
    }
    
    override var description : String {
        return NSData.init(bytes: self.value, length: self._size).description
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            NSUnimplemented()
        } else if aDecoder.containsValueForKey("NS.special") {
            NSUnimplemented()
        } else {
            guard let type = aDecoder.decodeObject() as? NSString else {
                return nil
            }
            
            let typep = type._swiftObject
            
            self.init(bytes: nil, objCType: typep)
            aDecoder.decodeValueOfObjCType(typep, at: self.value)
        }
    }
    
    static func supportsSecureCoding() -> Bool {
        return true
    }

    func encodeWithCoder(aCoder: NSCoder) {
        if !aCoder.allowsKeyedCoding {
            NSUnimplemented()
        } else if self._specialFlags != .NotSpecialType {
            NSUnimplemented()
        } else {
            aCoder.encodeObject(String.fromCString(self.objCType)!.bridge())
            aCoder.encodeValueOfObjCType(self.objCType, at: self.value)
        }
    }
    
    private var _size : Int {
        return self._typeInfo.value.size
    }
    
    private var value : UnsafeMutablePointer<Void> {
        return unsafeBitCast(self._value, UnsafeMutablePointer<Void>.self)
    }
    
    override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
}

internal func ==(x : NSConcreteValue, y : NSConcreteValue) -> Bool {
    return x._typeInfo == y._typeInfo
}

internal func ==(x : NSConcreteValue.TypeInfoHeader, y : NSConcreteValue.TypeInfoHeader) -> Bool {
    return x.name == y.name && x.size == y.size
}

internal func ==(x : NSConcreteValue.TypeInfo, y : NSConcreteValue.TypeInfo) -> Bool {
    return x.value == y.value
}

