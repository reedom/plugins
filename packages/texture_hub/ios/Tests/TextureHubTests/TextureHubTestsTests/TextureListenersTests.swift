//
//  TextureListenersTests.swift
//  TextureHubTestsTests
//
//  Created by tohru on 2019/10/13.
//  Copyright © 2019 FlutterPlugins. All rights reserved.
//

import XCTest
@testable import TextureHubTests

class TextureListenersTests: XCTestCase {
  func testNoArg() {
    let listeners = _TextureListeners()

    let listener1 = NSObject()
    listeners.addListener(listener1)
    let listener2 = NSObject()
    listeners.addListener(listener2)

    var calledCount = 0;
    listeners.invoke { l in
      calledCount += 1
      if calledCount == 1 {
        XCTAssertEqual(l, listener1)
        listeners.addListener(NSObject())
      } else {
        XCTAssertEqual(l, listener2)
      }
      listeners.removeListener(l)
    }
    XCTAssertEqual(2, calledCount)
  }

  func testWithArg() {
    let listeners = _TextureListeners()

    let listener1 = NSObject()
    listeners.addListener(listener1)
    let listener2 = NSObject()
    listeners.addListener(listener2)
    let arg = NSObject();

    var calledCount = 0;
    listeners.invoke(withArg: arg) { l, a in
      calledCount += 1
      if calledCount == 1 {
        XCTAssertEqual(l, listener1)
        listeners.addListener(NSObject())
      } else {
        XCTAssertEqual(l, listener2)
      }
      listeners.removeListener(l)
      XCTAssertEqual(a, arg)
    }
    XCTAssertEqual(2, calledCount)
  }
}
