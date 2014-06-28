## Type-Safe Associated Objects in Swift

TSAO is a small example of how to write type-safe associated objects using the
power of generics. Objective-C associated objects are useful, but they are also
untyped; every associated object is only known to be `id` at compile-time and
clients must either test the class at runtime or rely on it being the expected
type.

Generics allows us to do better. We can associate the value type with the key
used to reference the value, and this lets us provide a strongly-typed value at
compile-time with no runtime overhead. What's more, it allows us to store value
types as associated objects, not just class types, by transparently boxing the
value. This happens with again no runtime type-checking, although boxing a value
does require heap allocation so it's not entirely free.

It's also possible to specify the association policy. For all values,
atomic/nonatomic retain is supported. For class values, assign is also
supported. And for `NSCopying` values, atomic/nonatomic copy is supported.

A small usage sample is provided as `test.swift`, which will be compiled and run
via `make`.

### Usage example

```swift
// create a new key that stores the value type Int
let intKey: AssocKey<Int> = newAssocKey()

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
let strKey: AssocKey<NSString> = newAssocKey(copyAtomic: false)

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
