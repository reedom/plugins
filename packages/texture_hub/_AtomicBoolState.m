//
//  _AtomicBoolState.m
//  texture_hub
//
//  Created by tohru on 2019/10/14.
//

#import <Foundation/Foundation.h>
#import <stdatomic.h>
#import "_AtomicBoolState.h"

@implementation _AtomicBoolState {
  BOOL _Atomic _state;
}

- (BOOL)set {
  return !atomic_exchange(&_state, YES);
}

- (void)reset {
  atomic_exchange(&_state, NO);
}

@end
