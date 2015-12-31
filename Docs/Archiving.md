# Archiving Notes

There is a preliminary implementation of NSKeyedArchiver and NSKeyedUnarchiver which should be compatible with the OS X version.

* Owing to a limitation in the Swift runtime, only classes that explicitly a protocol conformance can be decoded.

* Archives with nested classes are presently incompatible with Darwin Foundation as there is no support for mangled class names.

* NSKeyedUnarchiver reads the entire plist into memory before constructing the object graph, it should construct it incrementally as does Foundation on OS X

* Paths that raise errors vs. calling _fatalError() need to be reviewed carefully

* The signature of the decoding APIs that take a class whitelist has changed from NSSet to [AnyClass] as AnyClass does not support Hashable

* classForKeyed[Un]Archiver has moved into NSObject so it can be overridden, move this back into an extension eventually

* Linux support is presently blocked on [SR-381]

# Classes

## Implemented

* NSArray
* NSCalendar
* NSCFArray (encodes as NSArray)
* NSCFDictionary (encodes as NSDictionary)
* NSCFSet (encodes as NSSet)
* NSCFString (encodes as NSString)
* NSConcreteValue
* NSData
* NSDate
* NSDictionary
* NSError
* NSLocale
* NSNotification
* NSNull (no-op)
* NSOrderedSet
* NSPersonNameComponents
* NSPort (not supported for keyed archiving)
* NSSet
* NSSpecialValue (for limited number of types)
* NSString
* NSTimeZone
* NSURL
* NSUUID
* NSValue (via class cluster hack)

## TODO

### Pending actual class implementation

* NSAttributedString

### Pending coder implementation

* NSAffineTransform
* NSCharacterSet
* NSDecimalNumber
* NSDecimalNumberHandler
* NSExpression
* NSIndexPath
* NSIndexSet
* NSPredicate
* NSSortDescriptor
* NSTextCheckingResult
* NSURLAuthenticationChallenge
* NSURLCache
* NSURLCredential
* NSURLProtectionSpace
* NSURLRequest
