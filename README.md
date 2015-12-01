## Type-Safe Associated Objects in Swift

[![GitHub Release](https://img.shields.io/github/release/kballard/swift-tsao.svg)](https://github.com/kballard/swift-tsao/releases/latest)
![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgrey.svg)
![Languages](https://img.shields.io/badge/languages-swift%202.1-orange.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/kballard/swift-tsao/blob/master/LICENSE.txt)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)][Carthage]

[Carthage]: https://github.com/carthage/carthage

TSAO is an implementation of type-safe associated objects in Swift. Objective-C
associated objects are useful, but they are also untyped; every associated
object is only known to be `id` at compile-time and clients must either test
the class at runtime or rely on it being the expected type.

Swift allows us to do better. We can associate the value type with the key used
to reference the value, and this lets us provide a strongly-typed value at
compile-time with no runtime overhead¹. What's more, it allows us to store
value types as associated objects, not just object types, by transparently
boxing the value (although this involves a heap allocation).

It's also possible to specify the association policy. For all values,
atomic/nonatomic retain is supported. For class values, assign is also
supported. And for `NSCopying` values, atomic/nonatomic copy is supported.

To properly use this library, the `AssocKey` values you create should be static
or global values (they should live for the lifetime of the program). You aren't
required to follow this rule, but any `AssocKey` you discard will end up
leaking an object (this is the only way to ensure safety without a runtime
penalty).

¹ If the compiler can't tell whether the value conforms to `AnyObject` due to
use in a generic context, it does require a type-check, but the optimizer
should be able to remove this check.

### Usage example

```swift
import TSAO

// create a new key that stores the value type Int
// note how this is a global value, so it lives for the whole program
let intKey = AssocKey<Int>()

// fetch the associated object from `obj` using `intKey`
func lookup_int_object(obj: AnyObject) -> Int? {
    // The get() method here returns an Int? because it takes intKey
    return associatedObjects(obj).get(intKey)
}

// set the associated object for `intKey` on `obj`
func set_int_object(obj: AnyObject, val: Int?) {
    // The set() method takes an Int? because of intKey
    // Trying to pass a different value type would be a compile-time error
    associatedObjects(obj).set(intKey, value: val)
}

// This key stores values of type NSString with the nonatomic copy policy
let strKey = AssocKey<NSString>(copyAtomic: false)

// fetch the associated object from `obj` using `strKey`
func lookup_str_object(obj: AnyObject) -> NSString? {
    // This get() method returns NSString? because of strKey
    return associatedObjects(obj).get(strKey)
}

// set the associated object for `strKey` on `obj`
func set_str_object(obj: AnyObject, val: NSString?) {
    // This set() method takes an NSString? value because of strKey
    // Trying to pass an Int like we did with intKey would be a compile-time
    // error
    associatedObjects(obj).set(strKey, value: val)
}
```
