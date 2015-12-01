// Type-Safe Associated Objects

import Foundation

/// AssocKey represents an associated objects key, with a given value type.
///
/// Keys should be toplevel let-bindings. Every key that is created will live
/// forever, even if you remove all references to it, so creating keys on the
/// fly can be a memory leak. This is done to preserve the type-safety of the
/// associated values.
///
/// Keys with a class value type may use the assign policy, and keys with a
/// value type that conforms to `NSCopying` may use the copy policy. Value types
/// must always use the default retain policy.
public struct AssocKey<ValueType> {
    /// Initializes an `AssocKey` with a retain policy.
    /// - Parameter atomic: Whether the policy should be atomic. Default is `false`.
    public init(atomic: Bool = false) {
        self.init(_policy: atomic ? .OBJC_ASSOCIATION_RETAIN : .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private init(_policy: objc_AssociationPolicy) {
        self._policy = _policy
    }

    private let _policy: objc_AssociationPolicy
    private let _key: _AssocKey = _AssocKey()
}

extension AssocKey where ValueType: AnyObject {
    /// Initializes an `AssocKey` with an assign policy.
    ///
    /// This looks a bit weird, but it can be invoked as `AssocKey(assign: ())`.
    public init(assign: ()) {
        self.init(_policy: .OBJC_ASSOCIATION_ASSIGN)
    }
}

extension AssocKey where ValueType: NSCopying {
    /// Initializes an `AssocKey` with a copy policy.
    ///
    /// - Parameter copyAtomic: Whether the policy should be atomic.
    public init(copyAtomic atomic: Bool) {
        self.init(_policy: atomic ? .OBJC_ASSOCIATION_COPY : .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
}

/// The data type that mediates access to associated objects.
///
/// Use the `associatedObjects()` function to create an instance of this type.
public struct AssociatedObjectView {
    private let _object: AnyObject

    private init(_private object: AnyObject) {
        _object = object
    }

    /// Get an associated object for a given key.
    // Ideally this would be a subscript operator but those don't support
    // generics.
    public func get<ValueType>(key: AssocKey<ValueType>) -> ValueType? {
        guard let value = _get(key) else { return nil }
        // use a type-check on ValueType instead of a type-check on the value
        // this way the optimizer can hopefully strip it out for us
        if ValueType.self is AnyObject {
            return unsafeBitCast(value, ValueType.self)
        } else {
            let box = unsafeBitCast(value, _AssocValueBox<ValueType>.self)
            return box._storage
        }
    }

    /// Get an associated object for a given key.
    // This is a slight optimization to remove the type-check for unoptimized
    // calls when we know the ValueType is an object at compile-time.
    public func get<ValueType: AnyObject>(key: AssocKey<ValueType>) -> ValueType? {
        guard let value = _get(key) else { return nil }
        // skip the runtime type test, we know it's the right type
        return unsafeBitCast(value, ValueType.self)
    }

    private func _get<ValueType>(key: AssocKey<ValueType>) -> AnyObject? {
        let p = UnsafePointer<()>(Unmanaged.passUnretained(key._key).toOpaque())
        return objc_getAssociatedObject(self._object, p)
    }

    /// Set an associated object for a given key.
    // Ideally this would be a mutating subscript operator but those don't
    // support generics.
    public func set<ValueType>(key: AssocKey<ValueType>, value: ValueType?) {
        // type-check the ValueType instead of the value to avoid obj-c
        // bridging. This way we'll match the expected behavior of get().
        // Hopefully the optimizer will strip this out for us.
        if ValueType.self is AnyObject {
            _set(key, value as! AnyObject?)
        } else if let v = value {
            _set(key, _AssocValueBox(v))
        } else {
            _set(key, nil)
        }
    }

    /// Set an associated object for a given key.
    // This is a slight optimization to remove the type-check for unoptimized
    // cals when we know the ValueType is an object at compile-time.
    public func set<ValueType: AnyObject>(key: AssocKey<ValueType>, value: ValueType?) {
        _set(key, value)
    }

    private func _set<ValueType>(key: AssocKey<ValueType>, _ value: AnyObject?) {
        let p = UnsafePointer<()>(Unmanaged.passUnretained(key._key).toOpaque())
        objc_setAssociatedObject(self._object, p, value, key._policy)
    }
}

/// Helper class that is used as the identity for the associated object key.
private final class _AssocKey {
    static var allKeys: [_AssocKey] = []
    static let keyQueue: dispatch_queue_t = {
        if #available(OSX 10.10, *) { // NOTE: Add iOS 8.0 to this check if using this file on a project that targets iOS 7
            return dispatch_queue_create("swift-tsao key queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0))
        } else {
            let queue = dispatch_queue_create("swift-tsao key queue", DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
            return queue
        }
    }()

    init() {
        // keep us alive forever
        dispatch_async(_AssocKey.keyQueue) {
            _AssocKey.allKeys.append(self)
        }
    }

    deinit {
        fatalError("_AssocKey should not be able to deinit")
    }
}

/// Helper class that wraps values for use with associated objects
private final class _AssocValueBox<ValueType> {
    var _storage: ValueType

    init(_ v: ValueType) {
        _storage = v
    }
}

/// Retrieve the associated object mapping for a given object.
public func associatedObjects(object: AnyObject) -> AssociatedObjectView {
    return AssociatedObjectView(_private: object)
}
