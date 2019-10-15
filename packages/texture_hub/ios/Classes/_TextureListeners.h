//
//  _TextureListeners.h
//  texture_hub
//
//  Created by tohru on 2019/10/13.
//

typedef void (^_InvokeFunc)(NSObject* _Nonnull listener);
typedef void (^_InvokeWithArgFunc)(NSObject* _Nonnull listener, NSObject* _Nullable arg);

/**
 * _TextureListeners stores a collection of listeners.
 *
 * _TextureListeners is designed to be thread-safe. It is safe to call `addListener`, `removeListener` and `removeAllListeners` during `invoke` iteration.
 */
@interface _TextureListeners: NSObject
/**
 * Create `_TextureListeners` instance.
 */
- (nonnull instancetype)init;

/**
 * Check whether the collection is empty.
 *
 * @return `true` if the collection is empty.
 */
- (BOOL)isEmpty;
/**
 * Add a listener to the collection.
 *
 * @param listener  A listener to be added. It is caller's responsibility to avoid duplication since `_TextureListeners` does not check of that.
 */
- (void)addListener:(nonnull NSObject*)listener;
/**
 * Remove a listner from the collection.
 *
 * @param listener  A listener to be removed. There will be no effect if the `listener` is not in the collection.
 */
- (void)removeListener:(nonnull NSObject*)listener;
/**
 * Drop all listeners in the collection.
 */
- (void)removeAllListeners;
/**
 * Invoke `callback` on each listener in the collection.
 *
 * It is safe to call `addListener`, `removeListener` and `removeAllListeners` during an iteration.
 *
 * @param callback  A function to be called on each listener.
 */
- (void)invoke:(nonnull _InvokeFunc)callback;
/**
 * Invoke `callback` on each listener in the collection.
 *
 * It is safe to call `addListener`, `removeListener` and `removeAllListeners` during an iteration.
 *
 * @param callback  A function to be called on each listener.
 */
- (void)invokeWithArg:(nullable NSObject*)arg callback:(nonnull _InvokeWithArgFunc)callback;

@end
