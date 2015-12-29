# Archiving Notes

There is a preliminary implementation of NSKeyedArchiver and NSKeyedUnarchiver which should be compatible with the OS X version.

* The implementation of NSStringFromClass() and NSClassFromString() currently uses private Swift API and does not support encoding classes that are not exported (i.e. cannot be looked up with dlsym()

* NSKeyedUnarchiver reads the entire plist into memory before constructing the object graph, it should construct it incrementally as does Foundation on OS X

* NSConcreteValue is only partially implemented, it does not have encoding complex types such as NSRange, NSPoint, NSRect, etc

* Paths that raise errors vs. calling _fatalError() need to be reviewed carefully

* The signature of the decoding APIs that take a class whitelist has changed from NSSet to [AnyClass] as AnyClass does not support Hashable

* classForKeyed[Un]Archiver has moved into NSObject so it can be overridden, move this back into an extension eventually

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
* NSConcreteValue encode and special
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
