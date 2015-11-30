import Foundation
import TSAO

let intKey = AssocKey<Int>()
let strKey = AssocKey<NSString>(copyAtomic: false)
let aryKey = AssocKey<[String]>()

let intKey2 = AssocKey<Int>()

class Foo: NSObject {}

func setup() -> Foo {
    let f = Foo()

    print("Setting a few associated objects...")
    // Note that each of these methods takes a strongly-typed value of the
    // correct associated type.
    // Trying to pass an Int to e.g. strKey would throw a compile-time error.
    associatedObjects(f).set(intKey, value: 42) // takes Int?
    associatedObjects(f).set(strKey, value: "this is an NSString") // takes NSString?
    associatedObjects(f).set(aryKey, value: ["array", "of", "String", "values"]) // takes String[]?

    return f
}

let f = setup()

print("\nFetching associated objects...")
// note that each one of these method calls is returning the actual type
// associated with the key, instead of returning Any or AnyObject
print("intKey: \(associatedObjects(f).get(intKey))") // returns Int?
print("strKey: \(associatedObjects(f).get(strKey))") // returns NSString?
print("aryKey: \(associatedObjects(f).get(aryKey))") // returns String[]?

print("\nFetching unset associated object...")
print("intKey2: \(associatedObjects(f).get(intKey2))") // returns Int?

print("\nSetting a copy associated value...")
let s = NSMutableString(string: "mutable string")
associatedObjects(f).set(strKey, value: s) // takes NSString?
print("strKey: \(s)")
print("\nMutating string...")
s.appendString(" with changes")
print("mutated: \(s)")
print("\nFetching copy associated value...")
print("strKey: \(associatedObjects(f).get(strKey))") // returns NSString?

print("\nClearing associated value...")
associatedObjects(f).set(aryKey, value: nil)           // takes String[]?
print("aryKey: \(associatedObjects(f).get(aryKey))") // returns String[]?
