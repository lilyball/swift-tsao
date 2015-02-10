import Foundation

let intKey: AssocKey<Int> = newAssocKey()
let strKey: AssocKey<NSString> = newAssocKey(copyAtomic: false)
let aryKey: AssocKey<[String]> = newAssocKey()

let intKey2: AssocKey<Int> = newAssocKey()

class Foo: NSObject {}

func setup() -> Foo {
    let f = Foo()

    println("Setting a few associated objects...")
    // Note that each of these methods takes a strongly-typed value of the
    // correct associated type.
    // Trying to pass an Int to e.g. strKey would throw a compile-time error.
    associatedObjects(f).set(intKey, value: 42) // takes Int?
    associatedObjects(f).set(strKey, value: "this is an NSString") // takes NSString?
    associatedObjects(f).set(aryKey, value: ["array", "of", "String", "values"]) // takes String[]?

    return f
}

// This is hacky, but I don't see any other way to do this right now, short of
// renaming the file to `main.swift`.
@asmname("main")
func main(argc: CInt, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> CInt {
    top_level_code()
    return 0
}

func top_level_code() {
    let f = setup()

    println("\nFetching associated objects...")
    // note that each one of these method calls is returning the actual type
    // associated with the key, instead of returning Any or AnyObject
    println("intKey: \(associatedObjects(f).get(intKey))") // returns Int?
    println("strKey: \(associatedObjects(f).get(strKey))") // returns NSString?
    println("aryKey: \(associatedObjects(f).get(aryKey))") // returns String[]?

    println("\nFetching unset associated object...")
    println("intKey2: \(associatedObjects(f).get(intKey2))") // returns Int?

    println("\nSetting a copy associated value...")
    let s = NSMutableString(string: "mutable string")
    associatedObjects(f).set(strKey, value: s) // takes NSString?
    println("strKey: \(s)")
    println("\nMutating string...")
    s.appendString(" with changes")
    println("mutated: \(s)")
    println("\nFetching copy associated value...")
    println("strKey: \(associatedObjects(f).get(strKey))") // returns NSString?

    println("\nClearing associated value...")
    associatedObjects(f).set(aryKey, value: nil)           // takes String[]?
    println("aryKey: \(associatedObjects(f).get(aryKey))") // returns String[]?
}
