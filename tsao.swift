// Type-safe Associated Objects

import Foundation

// use OnHeap for values

enum AssocPolicy {
    case Assign
    case Retain(atomic: Bool)
    case Copy(atomic: Bool)

    func _toObjc() -> objc_AssociationPolicy {
        switch self {
            case .Assign:
                return UInt(OBJC_ASSOCIATION_ASSIGN)
            case .Retain(atomic: let flag):
                return UInt(flag ? OBJC_ASSOCIATION_RETAIN : OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            case .Copy(atomic: let flag):
                return UInt(flag ? OBJC_ASSOCIATION_COPY : OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

// AssocKey represents an associated objects key, with a given value type.
class AssocKey<ValueType> {
    // note: for some reason objc_AssociationPolicy is a UInt but all the
    // defined values are computed properties of type Int.
    let _policy: objc_AssociationPolicy = UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    init() {}

    init(_private: AssocPolicy) {
        _policy = _private._toObjc()
    }
}

// Create a new AssocKey for any value
func newAssocKey<ValueType>() -> AssocKey<ValueType> {
    return AssocKey()
}

// Create a new AssocKey for any obj-c value with a given policy
func newAssocKey<ValueType: AnyObject>(policy: AssocPolicy) -> AssocKey<ValueType> {
    return AssocKey(_private: policy)
}

struct AssociatedObjectView {
    var _object: AnyObject

    init(_private object: AnyObject) {
        _object = object
    }

    // ideally this would be a subscript but those can't be generic
    func getValue<ValueType>(key: AssocKey<ValueType>) -> ValueType? {
        withObjectAtPlusZero(key) {
            (p: COpaquePointer) -> ValueType? in
            if let v: AnyObject = objc_getAssociatedObject(self._object, p) {
                return AssociatedObjectView._extractValue(v)
            }
            return nil
        }
    }

    func setValue<ValueType>(key: AssocKey<ValueType>, val: ValueType?) {
        withObjectAtPlusZero(key) {
            (p: COpaquePointer) -> () in
            if let v = val {
                objc_setAssociatedObject(self._object, p, AssociatedObjectView._boxValue(v), key._policy)
            } else {
                objc_setAssociatedObject(self._object, p, nil, key._policy)
            }
        }
    }

    static func _extractValue<ValueType: AnyObject>(v: AnyObject) -> ValueType {
        return v as ValueType
    }

    static func _extractValue<ValueType>(v: AnyObject) -> ValueType {
        // skip the runtime type test, we know it's the right type
        let box: _AssocValueBox<ValueType> = reinterpretCast(v)
        return box._storage
    }

    static func _boxValue<ValueType: AnyObject>(val: ValueType) -> AnyObject {
        return val
    }

    static func _boxValue<ValueType>(val: ValueType) -> AnyObject {
        return _AssocValueBox(val)
    }
}

class _AssocValueBox<ValueType> {
    // ideally this would store the value inline, but non-fixed class layouts are not currently supported
    var _storage: OnHeap<ValueType>

    init(_ v: ValueType) {
        _storage = OnHeap(v)
    }
}

func associatedObjects(inout object: AnyObject) -> AssociatedObjectView {
    return AssociatedObjectView(_private: object)
}
