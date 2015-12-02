## Type-Safe Associated Objects in Swift

[![Version](https://img.shields.io/badge/version-v2.0-blue.svg)](https://github.com/kballard/swift-tsao/releases/latest)
![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgrey.svg)
![Languages](https://img.shields.io/badge/languages-swift%202.1-orange.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/kballard/swift-tsao/blob/master/LICENSE.txt)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)][Carthage]
[![CocoaPods](https://img.shields.io/cocoapods/v/swift-tsao.svg)](http://cocoadocs.org/docsets/swift-tsao)

[Carthage]: https://github.com/carthage/carthage

TSAO is an implementation of type-safe associated objects in Swift. Objective-C
associated objects are useful, but they are also untyped; every associated
object is only known to be `id` at compile-time and clients must either test
the class at runtime or rely on it being the expected type.

Swift allows us to do better. We can associate the value type with the key used
to reference the value, and this lets us provide a strongly-typed value at
compile-time with no runtime overhead¹. What's more, it allows us to store
value types as associated objects, not just object types, by transparently
boxing the value (although this involves a heap allocation). We can also invert
the normal way associated objects work and present this type-safe adaptor using
the semantics of a global map from `AnyObject` to `ValueType`.

It's also possible to specify the association policy. For all values,
atomic/nonatomic retain is supported. For class values, assign is also
supported. And for `NSCopying` values, atomic/nonatomic copy is supported.

To properly use this library, the `AssocMap` values you create should be static
or global values (they should live for the lifetime of the program). You aren't
required to follow this rule, but any `AssocMap`s you discard will end up
leaking an object (this is the only way to ensure safety without a runtime
penalty).

¹ It does require a type-check, but the optimizer should in theory be able to
remove this check.

### Usage example

```swift
import TSAO

// create a new map that stores the value type Int
// note how this is a global value, so it lives for the whole program
let intMap = AssocMap<Int>()

// fetch the associated object from `obj` using `intMap`
func lookup_int_object(obj: AnyObject) -> Int? {
    // The subscript getter returns a value of type `Int?` so no casting is necessary
    return intMap[obj]
}

// set the associated object for `intMap` on `obj`
func set_int_object(obj: AnyObject, val: Int?) {
    // The subscript setter takes an `Int?` directly, trying to pass
    // a value of any other type would be a compile-time error
    intMap[obj] = val
}

// This map stores values of type NSString with the nonatomic copy policy
let strMap = AssocMap<NSString>(copyAtomic: false)

// fetch the associated object from `obj` using `strMap`
func lookup_str_object(obj: AnyObject) -> NSString? {
    // The subscrip getter returns a value of type `NSString?`
    return strMap[obj]
}

// set the associated object for `strMap` on `obj`
func set_str_object(obj: AnyObject, val: NSString?) {
    // The subscript setter takes an `NSString?` directly, trying to pass
    // an `Int?` like we did with `intMap` would be a compile-time error
    strMap[obj] = val
}
```
