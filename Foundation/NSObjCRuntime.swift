// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

#if os(OSX) || os(iOS)
internal let kCFCompareLessThan = CFComparisonResult.CompareLessThan
internal let kCFCompareEqualTo = CFComparisonResult.CompareEqualTo
internal let kCFCompareGreaterThan = CFComparisonResult.CompareGreaterThan
#endif

internal enum _NSSimpleObjCType : UnicodeScalar {
    case ID = "@"
    case Class = "#"
    case Sel = ":"
    case Char = "c"
    case UChar = "C"
    case Short = "s"
    case UShort = "S"
    case Int = "i"
    case UInt = "I"
    case Long = "l"
    case ULong = "L"
    case LongLong = "q"
    case ULongLong = "Q"
    case Float = "f"
    case Double = "d"
    case Bitfield = "b"
    case Bool = "B"
    case Void = "v"
    case Undef = "?"
    case Ptr = "^"
    case CharPtr = "*"
    case Atom = "%"
    case ArrayBegin = "["
    case ArrayEnd = "]"
    case UnionBegin = "("
    case UnionEnd = ")"
    case StructBegin = "{"
    case StructEnd = "}"
    case Vector = "!"
    case Const = "r"
}

extension Int {
    init(_ v: _NSSimpleObjCType) {
        self.init(UInt8(ascii: v.rawValue))
    }
}

extension Int8 {
    init(_ v: _NSSimpleObjCType) {
        self.init(Int(v))
    }
}

extension String {
    init(_ v: _NSSimpleObjCType) {
        self.init(v.rawValue)
    }
}

extension _NSSimpleObjCType {
    init?(_ v: UInt8) {
        self.init(rawValue: UnicodeScalar(v))
    }
    
    init?(_ v: String?) {
        if let rawValue = v?.unicodeScalars.first {
            self.init(rawValue: rawValue)
        } else {
            return nil
        }
    }
}

// mapping of ObjC types to sizes and alignments (note that .Int is 32-bit)
// FIXME use a generic function, unfortuantely this seems to promote the size to 8
private let _NSObjCSizesAndAlignments : Dictionary<_NSSimpleObjCType, (Int, Int)> = [
    .ID         : ( sizeof(AnyObject),              alignof(AnyObject)          ),
    .Class      : ( sizeof(AnyClass),               alignof(AnyClass)           ),
    .Char       : ( sizeof(CChar),                  alignof(CChar)              ),
    .UChar      : ( sizeof(UInt8),                  alignof(UInt8)              ),
    .Short      : ( sizeof(Int16),                  alignof(Int16)              ),
    .UShort     : ( sizeof(UInt16),                 alignof(UInt16)             ),
    .Int        : ( sizeof(Int32),                  alignof(Int32)              ),
    .UInt       : ( sizeof(UInt32),                 alignof(UInt32)             ),
    .Long       : ( sizeof(Int32),                  alignof(Int32)              ),
    .ULong      : ( sizeof(UInt32),                 alignof(UInt32)             ),
    .LongLong   : ( sizeof(Int64),                  alignof(Int64)              ),
    .ULongLong  : ( sizeof(UInt64),                 alignof(UInt64)             ),
    .Float      : ( sizeof(Float),                  alignof(Float)              ),
    .Double     : ( sizeof(Double),                 alignof(Double)             ),
    .Bool       : ( sizeof(Bool),                   alignof(Bool)               ),
    .CharPtr    : ( sizeof(UnsafePointer<CChar>),   alignof(UnsafePointer<CChar>))
]

internal func _NSGetSizeAndAlignment(type: _NSSimpleObjCType,
                                     inout _ size : Int,
                                     inout _ align : Int) -> Bool {
    guard let sizeAndAlignment = _NSObjCSizesAndAlignments[type] else {
        return false
    }
    
    size = sizeAndAlignment.0
    align = sizeAndAlignment.1
    
    return true
}

public func NSGetSizeAndAlignment(typePtr: UnsafePointer<Int8>,
                                  _ sizep: UnsafeMutablePointer<Int>,
                                  _ alignp: UnsafeMutablePointer<Int>) -> UnsafePointer<Int8> {
    let type = _NSSimpleObjCType(UInt8(typePtr.memory))!

    var size : Int = 0
    var align : Int = 0
    
    if !_NSGetSizeAndAlignment(type, &size, &align) {
        return nil
    }
    
    if sizep != nil {
        sizep.memory = size
    }
    
    if alignp != nil {
        alignp.memory = align
    }

    return typePtr.advancedBy(1)
}

public enum NSComparisonResult : Int {
    
    case OrderedAscending = -1
    case OrderedSame
    case OrderedDescending
    
    internal static func _fromCF(val: CFComparisonResult) -> NSComparisonResult {
        if val == kCFCompareLessThan {
            return .OrderedAscending
        } else if  val == kCFCompareGreaterThan {
            return .OrderedDescending
        } else {
            return .OrderedSame
        }
    }
}

/* Note: QualityOfService enum is available on all platforms, but it may not be implemented on all platforms. */
public enum NSQualityOfService : Int {
    
    /* UserInteractive QoS is used for work directly involved in providing an interactive UI such as processing events or drawing to the screen. */
    case UserInteractive
    
    /* UserInitiated QoS is used for performing work that has been explicitly requested by the user and for which results must be immediately presented in order to allow for further user interaction.  For example, loading an email after a user has selected it in a message list. */
    case UserInitiated
    
    /* Utility QoS is used for performing work which the user is unlikely to be immediately waiting for the results.  This work may have been requested by the user or initiated automatically, does not prevent the user from further interaction, often operates at user-visible timescales and may have its progress indicated to the user by a non-modal progress indicator.  This work will run in an energy-efficient manner, in deference to higher QoS work when resources are constrained.  For example, periodic content updates or bulk file operations such as media import. */
    case Utility
    
    /* Background QoS is used for work that is not user initiated or visible.  In general, a user is unaware that this work is even happening and it will run in the most efficient manner while giving the most deference to higher QoS work.  For example, pre-fetching content, search indexing, backups, and syncing of data with external systems. */
    case Background
    
    /* Default QoS indicates the absence of QoS information.  Whenever possible QoS information will be inferred from other sources.  If such inference is not possible, a QoS between UserInitiated and Utility will be used. */
    case Default
}

public struct NSSortOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let Concurrent = NSSortOptions(rawValue: UInt(1 << 0))
    public static let Stable = NSSortOptions(rawValue: UInt(1 << 4))
}

public struct NSEnumerationOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let Concurrent = NSEnumerationOptions(rawValue: UInt(1 << 0))
    public static let Reverse = NSEnumerationOptions(rawValue: UInt(1 << 1))
}

public typealias NSComparator = (AnyObject, AnyObject) -> NSComparisonResult

public let NSNotFound: Int = Int.max

@noreturn internal func NSRequiresConcreteImplementation(fn: String = __FUNCTION__, file: StaticString = __FILE__, line: UInt = __LINE__) {
    fatalError("\(fn) must be overriden in subclass implementations", file: file, line: line)
}

@noreturn internal func NSUnimplemented(fn: String = __FUNCTION__, file: StaticString = __FILE__, line: UInt = __LINE__) {
    fatalError("\(fn) is not yet implemented", file: file, line: line)
}

@noreturn internal func NSInvalidArgument(message: String, method: String = __FUNCTION__, file: StaticString = __FILE__, line: UInt = __LINE__) {
    fatalError("\(method): \(message)", file: file, line: line)
}

internal struct _CFInfo {
    // This must match _CFRuntimeBase
    var info: UInt32
    var pad : UInt32
    init(typeID: CFTypeID) {
        // This matches what _CFRuntimeCreateInstance does to initialize the info value
        info = UInt32((UInt32(typeID) << 8) | (UInt32(0x80)))
        pad = 0
    }
    init(typeID: CFTypeID, extra: UInt32) {
        info = UInt32((UInt32(typeID) << 8) | (UInt32(0x80)))
        pad = extra
    }
}

internal protocol _CFBridgable {
    typealias CFType
    var _cfObject: CFType { get }
}

internal protocol  _SwiftBridgable {
    typealias SwiftType
    var _swiftObject: SwiftType { get }
}

internal protocol _NSBridgable {
    typealias NSType
    var _nsObject: NSType { get }
}

#if os(OSX) || os(iOS)
private let _SwiftFoundationModuleName = "SwiftFoundation"
#else
private let _SwiftFoundationModuleName = "Foundation"
#endif

/**
    Returns the class name for a class. For compatibility with Foundation on Darwin,
    Foundation classes are returned as unqualified names.

    This is temporarily an internal function until _typeByName() works for all classes.
 */
internal func NSStringFromClass(aClass: AnyClass) -> String {
    let aClassName = _typeName(aClass).bridge()
    let components = aClassName.componentsSeparatedByString(".")
    
    if components.count == 2 {
        if components[0] == _SwiftFoundationModuleName {
            return components[1]
        } else {
            return String(aClassName)
        }
    } else {
        fatalError("NSStringFromClass could not determine name for class '\(aClass)'")
    }
}

/**
    Returns the class metadata given a string. For compatibility with Foundation on Darwin,
    unqualified names are looked up in the Foundation module. Owing to a present limitation
    of the Swift runtime, only classes conforming to a known protocol can be looked up.

    This is temporarily an internal function until _typeByName() works for all classes.
 */
internal func NSClassFromString(aClassName: String) -> AnyClass? {
    var aClass : Any.Type? = nil

    if aClassName.characters.indexOf(".") == nil {
        aClass = _typeByName(_SwiftFoundationModuleName + "." + aClassName)
    } else {
        aClass = _typeByName(aClassName)
    }

    return aClass as? AnyClass
}

// _typeByName() only works for classes with explicit protocol conformances, so subclasses
// such as NSMutableDictionary and MSMutableArray that inherit their conformances cannot be
// looked up by name. We declare a dummy protocol here until this issue is resolved.
internal protocol __NSDummyProtocol {}
