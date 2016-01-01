// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal protocol NSSpecialValueCoding : NSSecureCoding {
    static func objCType() -> String
    
    // Ideally we would make NSSpecialValue a generic class and specialise it for
    // NSPoint, etc, but then we couldn't implement NSValue.init?(coder:) because 
    // it's not yet possible to specialise classes with a type determined at runtime.
    //
    // Nor can we make NSSecureCoding conform to Equatable because it has associated
    // type requirements.
    //
    
    
    // So in order to implement equality we have the hack below.
    func isEqual(value: Any) -> Bool
}

internal class NSSpecialValue : NSValue {

    // Originally these were functions in NSSpecialValueCoding but it's probably
    // more convenient to keep it as a table here as nothing else really needs to
    // know about them
    private static let _specialTypes : Dictionary<Int, NSSpecialValueCoding.Type> = [
        1   : NSPoint.self,
        2   : NSSize.self,
        3   : NSRect.self,
        12  : NSEdgeInsets.self
    ]
    
    private static func _typeFromFlags(flags: Int) -> NSSpecialValueCoding.Type? {
        return _specialTypes[flags]
    }
    
    private static func _flagsFromType(type: NSSpecialValueCoding.Type) -> Int {
        for (F, T) in _specialTypes {
            if T == type {
                return F
            }
        }
        return 0
    }
    
    private static func _objCTypeFromType(type: NSSpecialValueCoding.Type) -> String? {
        for (_, T) in _specialTypes {
            if T == type {
                return T.objCType()
            }
        }
        return nil
    }
    
    internal var _value : NSSpecialValueCoding
    
    init(_ value: NSSpecialValueCoding) {
        self._value = value
    }
    
    internal var value : NSSpecialValueCoding {
        return _value
    }
    
    required init(bytes value: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        // This is a bit tricky to implement with Swift because you can't cast pointers of different sizes
        NSUnimplemented()
    }

    convenience required init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            NSUnimplemented()
        } else {
            let specialFlags = aDecoder.decodeIntegerForKey("NS.special")
            guard let specialType = NSSpecialValue._typeFromFlags(specialFlags) else {
                return nil
            }
            
            guard let specialValue = specialType.init(coder: aDecoder) else {
                return nil
            }
            
            self.init(specialValue)
        }
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        if !aCoder.allowsKeyedCoding {
            NSUnimplemented()
        } else {
            aCoder.encodeInteger(NSSpecialValue._flagsFromType(self.value.dynamicType), forKey: "NS.special")
            self.value.encodeWithCoder(aCoder)
        }
    }
    
    override var objCType : UnsafePointer<Int8> {
        let typeName = NSSpecialValue._objCTypeFromType(self.value.dynamicType)
        return typeName!.bridge().UTF8String // leaky
    }
    
    override var classForKeyedArchiver: AnyClass? {
        // for some day when we support class clusters
        return NSValue.self
    }
    
    override var description : String {
        if let printable = self.value as? CustomStringConvertible {
            return printable.description
        } else {
            return super.description
        }
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if self === object {
            return true
        } else if let special = object as? NSSpecialValue {
            return self.value.isEqual(special.value)
        } else {
            return false
        }
    }
}