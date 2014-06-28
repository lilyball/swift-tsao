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

A small usage sample is provided as `test.swift`, which will be compiled and run
via `make`.

### Usage example

```swift
// create a new key that stores the value type Int
let intKey: AssocKey<Int> = newAssocKey()

// fetch the associated object from `obj` using `intKey`
func lookup_int_object(obj: AnyObject) -> Int? {
    return associatedObjects(obj).get(intKey)
}
```

It's also possible to specify the association policy. For all values,
atomic/nonatomic retain is supported. For class values, assign is also
supported. And for `NSCopying` values, atomic/nonatomic copy is supported.
