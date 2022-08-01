// Type-Safe Associated Objects

import Foundation

/// `AssocMap` represents a map from `AnyObject`s to `ValueType`, using associated
/// objects as the storage mechanism. Like associated objects, the `AnyObject`
/// value is not retained, and the `ValueType` will be destructed immediately
/// when the `AnyObject` deinits.
///
/// Maps should be toplevel or static let-bindings. Every map that is created
/// will live forever, even if you remove all references to it, so creating maps
/// on the fly can be a memory leak. This is done to preserve the safety of the
/// associated values without a runtime penalty.
///
/// Maps with a class value type may use the assign policy, and maps with a
/// value type that conforms to `NSCopying` may use the copy policy. Value types
/// must always use the default retain policy.
public struct AssocMap<ValueType> {
    /// Initializes an `AssocMap` with a retain policy.
    /// - Parameter atomic: Whether the policy should be atomic. Default is `false`.
    public init(atomic: Bool = false) {
        self.init(_policy: atomic ? .OBJC_ASSOCIATION_RETAIN : .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Gets or sets an associated value for a given object.
    public subscript(object: AnyObject) -> ValueType? {
        get {
            guard let value = _get(object) else { return nil }
            // use a type-check on ValueType instead of a type-check on the value
            // this way the optimizer can hopefully strip it out for us
            if ValueType.self is AnyObject.Type {
                return unsafeBitCast(value, to: ValueType.self)
            } else {
                let box = unsafeBitCast(value, to: _AssocValueBox<ValueType>.self)
                return box._storage
            }
        }
        nonmutating set {
            // type-check the ValueType instead of the value to avoid obj-c bridging.
            // This way we'll match the expected boxing behavior of the getter.
            // Hopefully the optimizer will strip this out for us.
            if ValueType.self is AnyObject.Type {
                _set(object, newValue as AnyObject?)
            } else if let v = newValue {
                _set(object, _AssocValueBox<ValueType>(v))
            } else {
                _set(object, nil)
            }
        }
    }

    fileprivate init(_policy: objc_AssociationPolicy, useWeakObjectContainer: Bool = false) {
        precondition(!useWeakObjectContainer || _policy == .OBJC_ASSOCIATION_RETAIN)
        self._policy = _policy
        self.useWeakObjectContainer = useWeakObjectContainer
    }

    private let _policy: objc_AssociationPolicy
    private let _key: _AssocKey = _AssocKey()
    private let useWeakObjectContainer: Bool
    
    private func _get(_ object: AnyObject) -> AnyObject? {
        let p = Unmanaged.passUnretained(_key).toOpaque()
        if useWeakObjectContainer {
            return (objc_getAssociatedObject(object, p) as? WeakObjectContainer)?.object
        } else {
            return objc_getAssociatedObject(object, p) as AnyObject?
        }
    }
    
    private func _set(_ object: AnyObject, _ value: AnyObject?) {
        let p = Unmanaged.passUnretained(_key).toOpaque()
        if useWeakObjectContainer {
            let container = (objc_getAssociatedObject(object, p) as? WeakObjectContainer) ?? {
               let new = WeakObjectContainer()
                objc_setAssociatedObject(object, p, new, _policy)
                return new
            }()
            container.object = value
        } else {
            objc_setAssociatedObject(object, p, value, _policy)
        }
    }
}

extension AssocMap where ValueType: AnyObject {
    /// Initializes an `AssocMap` with an assign policy.
    ///
    /// This looks a bit weird, but it can be invoked as `AssocMap(assign: ())`.
    public init(assign: ()) {
        self.init(_policy: .OBJC_ASSOCIATION_ASSIGN)
    }
    
    /// Initializes an `AssocMap` with a safe assign policy. Accessing the value will return nil if object has been deallocated.
    public init(safeAssign: ()) {
        self.init(_policy: .OBJC_ASSOCIATION_RETAIN, useWeakObjectContainer: true)
    }
}

extension AssocMap where ValueType: NSCopying {
    /// Initializes an `AssocMap` with a copy policy.
    ///
    /// - Parameter copyAtomic: Whether the policy should be atomic.
    public init(copyAtomic atomic: Bool) {
        self.init(_policy: atomic ? .OBJC_ASSOCIATION_COPY : .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
}

/// Helper class that is used as the identity for the associated object key.
private final class _AssocKey {
    static var allKeys: [_AssocKey] = []
    static let keyQueue: DispatchQueue = {
        if #available(OSX 10.10, *) { // NOTE: Add iOS 8.0 to this check if using this file on a project that targets iOS 7
            return DispatchQueue(label: "swift-tsao key queue", qos: .background)
        } else {
            return DispatchQueue(label: "swift-tsao key queue", target: DispatchQueue.global(priority: .background))
        }
    }()

    init() {
        // keep us alive forever
        _AssocKey.keyQueue.async {
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

private final class WeakObjectContainer {
    weak var object: AnyObject?
}
