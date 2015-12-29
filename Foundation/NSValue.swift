// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSValue : NSObject, NSCopying, NSSecureCoding, NSCoding {

    private static var SideTable = [ObjectIdentifier : NSConcreteValue]()
    private static var SideTableLock = NSLock()

    internal override init() {
        super.init()
        // on Darwin [NSValue new] returns nil
    }
    
    deinit {
        if self.dynamicType == NSValue.self {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)] = nil
            }
        }
    }
    
    public func getValue(value: UnsafeMutablePointer<Void>) {
        if self.dynamicType == NSValue.self {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)]!.getValue(value)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public var objCType: UnsafePointer<Int8> {
        if self.dynamicType == NSValue.self {
            return NSValue.SideTableLock.synchronized {
                return NSValue.SideTable[ObjectIdentifier(self)]!.objCType
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience required init(bytes value: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        if self.dynamicType == NSValue.self {
            self.init()
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)] = NSConcreteValue(bytes: value, objCType: type)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // no need to check concrete map as this is delegated via classForKeyedArchiver
        NSRequiresConcreteImplementation()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if self.dynamicType == NSValue.self {
            NSValue.SideTableLock.synchronized {
                NSValue.SideTable[ObjectIdentifier(self)]!.encodeWithCoder(aCoder)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public override class func classForKeyedUnarchiver() -> AnyClass {
        return NSConcreteValue.self
    }
    
    
}

