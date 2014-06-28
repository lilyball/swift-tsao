import Foundation

let intKey: AssocKey<Int> = newAssocKey()
let strKey: AssocKey<NSString> = newAssocKey(copyAtomic: false)
let aryKey: AssocKey<String[]> = newAssocKey()

class Foo: NSObject {}

func setup() -> Foo {
    let f = Foo()

    println("Setting a few associated objects...")
    associatedObjects(f).set(intKey, value: 42)
    associatedObjects(f).set(strKey, value: "this is an NSString")
    associatedObjects(f).set(aryKey, value: ["array", "of", "String", "values"])

    return f
}

// this is hacky, but I'm not sure how to do this from the terminal otherwise
@asmname("main") func main() {
    let f = setup()

    println("\nFetching associated objects...")
    println("intKey: \(associatedObjects(f).get(intKey))")
    println("strKey: \(associatedObjects(f).get(strKey))")
    println("aryKey: \(associatedObjects(f).get(aryKey))")

    println("\nSetting a copy associated value...")
    let s = NSMutableString(string: "mutable string")
    associatedObjects(f).set(strKey, value: s)
    println("strKey: \(s)")
    println("\nMutating string...")
    s.appendString(" with changes")
    println("mutated: \(s)")
    println("\nFetching copy associated value...")
    println("strKey: \(associatedObjects(f).get(strKey))")
}
