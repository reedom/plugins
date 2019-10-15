//
//  _TextureListeners.m
//  texture_hub
//
//  Created by tohru on 2019/10/13.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>
#import "_TextureListeners.h"

@implementation _TextureListeners {
  NSMutableArray* _listeners;
  dispatch_queue_t _dispatch_queue;
}

- (nonnull instancetype)init {
  self = [super init];
  _listeners = [NSMutableArray new];
  
  NSString* queue_name = [NSString stringWithFormat:@"flutter.plugins.io/texture_hub/TextureListeners/%lu", (unsigned long)self.hash];
  _dispatch_queue = dispatch_queue_create([queue_name cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);
  return self;
}

- (BOOL)isEmpty {
  return _listeners.count == 0;
}

- (void)addListener:(nonnull NSObject*)listener {
  dispatch_barrier_sync(_dispatch_queue, ^{
    [_listeners addObject:listener];
  });
}

- (void)removeListener:(nonnull NSObject*)listener {
  dispatch_barrier_sync(_dispatch_queue, ^{
    [_listeners removeObject:listener];
  });
}

- (void)removeAllListeners {
  dispatch_barrier_sync(_dispatch_queue, ^{
    [_listeners removeAllObjects];
  });
}

- (void)invoke:(nonnull _InvokeFunc)callback {
  if (_listeners.count == 0) {
    return;
  }
  
  __block NSArray* copy;
  dispatch_barrier_sync(_dispatch_queue, ^{
    copy = [NSArray arrayWithArray:self->_listeners];
  });

  __block int i = 0;
  __block NSObject* listener = nil;
  while (i < copy.count) {
    dispatch_barrier_sync(_dispatch_queue, ^{
      while (i < copy.count) {
        listener = copy[i++];
        if ([_listeners indexOfObject:listener] != NSNotFound) {
          break;
        } else {
          listener = nil;
        }
      }
    });
    if (listener) {
      callback(listener);
    }
  }
}

- (void)invokeWithArg:(nullable NSObject*)arg callback:(nonnull _InvokeWithArgFunc)callback {
  if (_listeners.count == 0) {
    return;
  }
  
  
  __block NSArray* copy;
  dispatch_barrier_sync(_dispatch_queue, ^{
    copy = [NSArray arrayWithArray:self->_listeners];
  });

  __block int i = 0;
  __block NSObject* listener = nil;
  while (i < copy.count) {
    dispatch_barrier_sync(_dispatch_queue, ^{
      while (i < copy.count) {
        listener = copy[i++];
        if ([_listeners indexOfObject:listener] != NSNotFound) {
          break;
        } else {
          listener = nil;
        }
      }
    });
    if (listener) {
      callback(listener, arg);
    }
  }
}

@end
