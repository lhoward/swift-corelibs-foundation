// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

#if os(OSX) || os(iOS)
// can't subclass NSObject yet on Linux
public class UserClass : NSObject, NSSecureCoding {
    var ivar : Int = 0
    
    public class func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder : NSCoder) {
        aCoder.encodeInteger(ivar, forKey:"$custom") // also test escaping
    }
    
    init(_ value: Int) {
        self.ivar = value
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.ivar = aDecoder.decodeIntegerForKey("$custom")
    }
    
    public override var description: String {
        get {
            return "UserClass \(ivar)"
        }
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let custom = object as? UserClass {
            return self.ivar == custom.ivar
        } else {
            return false
        }
    }
}
#endif

class TestNSKeyedArchiver : XCTestCase {
    var allTests : [(String, () -> Void)] {
        return [
            ("test_archive_array", test_archive_array),
            ("test_archive_concrete_value", test_archive_concrete_value),
            ("test_archive_dictionary", test_archive_dictionary),
            ("test_archive_generic_objc", test_archive_generic_objc),
            //("test_archive_locale", test_archive_locale), // not isEqual()
            ("test_archive_string", test_archive_string),
            ("test_archive_mutable_array", test_archive_mutable_array),
            ("test_archive_mutable_dictionary", test_archive_mutable_dictionary),
            ("test_archive_nspoint", test_archive_nspoint),
            ("test_archive_nsrect", test_archive_nsrect),
            ("test_archive_null", test_archive_null),
            ("test_archive_set", test_archive_set),
            ("test_archive_url", test_archive_url),
            ("test_archive_user_class", test_archive_user_class),
            ("test_archive_uuid", test_archive_uuid),
        ]
    }

    private func test_archive(encode: (NSKeyedArchiver) -> Bool,
                              decode: (NSKeyedUnarchiver) -> Bool) {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        
        XCTAssertTrue(encode(archiver))
        archiver.finishEncoding()
        
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        XCTAssertTrue(decode(unarchiver))
    }

    private func test_archive(object : NSObject, allowsSecureCoding : Bool = true) {
        test_archive({ archiver -> Bool in
                archiver.requiresSecureCoding = allowsSecureCoding
                archiver.encodeObject(object, forKey: NSKeyedArchiveRootObjectKey)
                archiver.finishEncoding()
                return true
            },
            decode: { unarchiver -> Bool in
                unarchiver.requiresSecureCoding = allowsSecureCoding
                
                do {
                    guard let root = try unarchiver.decodeTopLevelObjectOfClasses([object.dynamicType],
                        forKey: NSKeyedArchiveRootObjectKey) as? NSObject else {
                        XCTFail("Unable to decode data")
                        return false
                    }
                    XCTAssertEqual(object, root, "unarchived object \(root) does not match \(object)")
                } catch {
                    XCTFail("Error thrown: \(error)")
                }
                return true
        })
    }
    
    func test_archive_array() {
        let array = ["one", "two", "three"]
        test_archive(array.bridge())
    }
    
    func test_archive_concrete_value() {
        let array: Array<UInt64> = [12341234123, 23452345234, 23475982345, 9893563243, 13469816598]
        let objctype = "[5Q]"
        array.withUnsafeBufferPointer { cArray in
            let concrete = NSValue(bytes: cArray.baseAddress, objCType: objctype)
            test_archive(concrete)
        }
    }
    
    func test_archive_dictionary() {
        let dictionary = ["one" : 1, "two" : 2, "three" : 3]
        test_archive(dictionary.bridge())
    }
    
    func test_archive_generic_objc() {
        let array: Array<Int32> = [1234, 2345, 3456, 10000]

        test_archive({ archiver -> Bool in
            array.withUnsafeBufferPointer { cArray in
                archiver.encodeValueOfObjCType("[4i]", at: cArray.baseAddress)
            }
            return true
        },
        decode: {unarchiver -> Bool in
            var expected: Array<Int32> = [0, 0, 0, 0]
            expected.withUnsafeMutableBufferPointer {(inout p: UnsafeMutableBufferPointer<Int32>) in
                unarchiver.decodeValueOfObjCType("[4i]", at: UnsafeMutablePointer<Void>(p.baseAddress))
            }
            XCTAssertEqual(expected, array)
            return true
            })
    }

    func test_archive_locale() {
        let locale = NSLocale.currentLocale()
        test_archive(locale)
    }
    
    func test_archive_string() {
        let string = "hello"
        test_archive(string.bridge())
    }
    
    func test_archive_mutable_array() {
        let array = ["one", "two", "three"]
        test_archive(array.bridge().mutableCopy() as! NSObject)
    }

    func test_archive_mutable_dictionary() {
        let mdictionary = NSMutableDictionary(objects: [NSNumber(integer: 1), NSNumber(integer: 2), NSNumber(integer: 3)],
                                              forKeys: ["one".bridge(), "two".bridge(), "three".bridge()])
        test_archive(mdictionary)
    }
    
    func test_archive_nspoint() {
        let point = NSValue(point: NSPoint(x: CGFloat(20.0), y: CGFloat(35.0)))
        test_archive(point)
    }
    
    func test_archive_nsrect() {
        let point = NSPoint(x: CGFloat(20.0), y: CGFloat(35.4))
        let size = NSSize(width: CGFloat(50.0), height: CGFloat(155.0))

        let rect = NSValue(rect: NSRect(origin: point, size: size))
        test_archive(rect)
    }

    func test_archive_null() {
        let null = NSNull()
        test_archive(null)
    }
    
    func test_archive_set() {
        let set = NSSet(array: [NSNumber(integer: 1234234), NSNumber(integer: 2374853)])
        test_archive(set)
    }
    
    func test_archive_url() {
        let url = NSURL(string: "index.html", relativeToURL:NSURL(string: "http://www.apple.com"))!
        test_archive(url)
    }
    
    func test_archive_user_class() {
        #if os(OSX) || os(iOS)
            let userClass = UserClass(1234)
            test_archive(userClass)
        #endif
    }
    
    func test_archive_uuid() {
        let uuid = NSUUID()
        test_archive(uuid)
    }
}
