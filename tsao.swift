// Type-safe Associated Objects

import Foundation

// AssocKey represents an associated objects key, with a given value type.
//
// Create new keys with newAssocKey(). Keys should be toplevel let-bindings
// and should never deinit. If a key deinits, an assertion is thrown.
// This is to preserve the type-safety of the associated values.
//
// Keys with a class value type may use the assign policy, and keys with a
// value type that conforms to NSCopying may use the copy policy. Value types
// must always use the default retain policy.
//
// @see newAssocKey
class AssocKey<ValueType> {
    let _policy: objc_AssociationPolicy

    init(_private: objc_AssociationPolicy) {
        _policy = _private
    }

    deinit {
        assert(false, "AssocKey must not deinit")
    }
}

// Create a new AssocKey for any value.
//
// This uses the retain policy.
func newAssocKey<ValueType>(atomic: Bool = false) -> AssocKey<ValueType> {
    let policy = atomic ? OBJC_ASSOCIATION_RETAIN : OBJC_ASSOCIATION_RETAIN_NONATOMIC
    return AssocKey(_private: objc_AssociationPolicy(policy))
}

// Create a new AssocKey for any class value with the assign policy.
//
// This looks a bit weird, but it can be invoked as <tt>newAssocKey(assign: ())</tt>.
func newAssocKey<ValueType: AnyObject>(#assign: ()) -> AssocKey<ValueType> {
    return AssocKey(_private: objc_AssociationPolicy(OBJC_ASSOCIATION_ASSIGN))
}

// Create a new AssocKey for any NSCopying value with the copy policy.
func newAssocKey<ValueType: NSCopying>(copyAtomic atomic: Bool) -> AssocKey<ValueType> {
    let policy = atomic ? OBJC_ASSOCIATION_COPY : OBJC_ASSOCIATION_COPY_NONATOMIC
    return AssocKey(_private: objc_AssociationPolicy(policy))
}

// The data type that mediates access to associated objects.
//
// Use the associatedObjects() function to create an instance of this type.
struct AssociatedObjectView {
    var _object: AnyObject

    init(_private object: AnyObject) {
        _object = object
    }

    // Get an associated object for a given key.
    //
    // Ideally this would be a subscript operator but those don't support
    // generics.
    func get<ValueType>(key: AssocKey<ValueType>) -> ValueType? {
        return _get(key) {
            // skip the runtime type test, we know it's the right type
            let box: _AssocValueBox<ValueType> = reinterpretCast($0)
            return box._storage
        }
    }

    func get<ValueType: AnyObject>(key: AssocKey<ValueType>) -> ValueType? {
        return _get(key) {
            // skip the runtime type test, we know it's the right type
            return reinterpretCast($0)
        }
    }

    func _get<ValueType>(key: AssocKey<ValueType>, _ f: AnyObject -> ValueType) -> ValueType? {
        return withObjectAtPlusZero(key) {
            (p: COpaquePointer) -> ValueType? in
            if let v: AnyObject = objc_getAssociatedObject(self._object, p) {
                return f(v)
            }
            return nil
        }
    }

    // Set an associated object for a given key.
    //
    // Ideally this would be a mutating subscript operator but those don't
    // support generics.
    func set<ValueType>(key: AssocKey<ValueType>, value: ValueType?) {
        if let v = value {
            _set(key, _AssocValueBox(v))
        } else {
            _set(key, nil)
        }
    }

    func set<ValueType: AnyObject>(key: AssocKey<ValueType>, value: ValueType?) {
        _set(key, value)
    }

    func _set<ValueType>(key: AssocKey<ValueType>, _ value: AnyObject?) {
        withObjectAtPlusZero(key) {
            (p: COpaquePointer) -> () in
            if let v: AnyObject = value {
                objc_setAssociatedObject(self._object, p, v, key._policy)
            } else {
                objc_setAssociatedObject(self._object, p, nil, key._policy)
            }
        }
    }
}

class _AssocValueBox<ValueType> {
    // this should store the value inline, but non-fixed class layouts are not
    // currently supported
    var _storage: OnHeap<ValueType>

    init(_ v: ValueType) {
        _storage = OnHeap(v)
    }
}

// Retrieve the associated object mapping for a given object.
func associatedObjects(object: AnyObject) -> AssociatedObjectView {
    return AssociatedObjectView(_private: object)
}
