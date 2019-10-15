//
//  TextureValueTests.swift
//  TextureHubTestsTests
//
//  Created by tohru on 2019/10/13.
//  Copyright © 2019 FlutterPlugins. All rights reserved.
//

import XCTest
@testable import TextureHubTests

class TextureValueTests: XCTestCase {
  @inline(__always) func createPixelBuffer() -> CVPixelBuffer {
    let options = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                   kCVPixelBufferCGBitmapContextCompatibilityKey as String: true] as CFDictionary
    var pixelBuffer: CVPixelBuffer!
    let status = CVPixelBufferCreate(kCFAllocatorDefault, 16, 16, OSType(kCVPixelFormatType_32BGRA), options, &pixelBuffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    return pixelBuffer
  }

  func testInitialState() {
    let value = _TextureValue()
    XCTAssertNil(value.getPixelBufferRetained())
  }
  
  func testNoCopy() {
    let value = _TextureValue()

    let pixelBuffer = createPixelBuffer()
    value.storePixelBufferNoCopy(pixelBuffer)
    var returnedPixelBuffer = value.getPixelBufferRetained()
    XCTAssertEqual(pixelBuffer, returnedPixelBuffer)

    let pixelBuffer2 = createPixelBuffer()
    value.storePixelBufferNoCopy(pixelBuffer2)
    returnedPixelBuffer = value.getPixelBufferRetained()
    XCTAssertEqual(pixelBuffer2, returnedPixelBuffer)
  }

  func testCopy() {
    let value = _TextureValue()

    let pixelBuffer = createPixelBuffer()
    var copiedPixelBuffer = value.storePixelBufferCopy(pixelBuffer)
    XCTAssertNotEqual(pixelBuffer, copiedPixelBuffer)
    var returnedPixelBuffer = value.getPixelBufferRetained()
    XCTAssertEqual(copiedPixelBuffer, returnedPixelBuffer)

    let pixelBuffer2 = createPixelBuffer()
    copiedPixelBuffer = value.storePixelBufferCopy(pixelBuffer2)
    XCTAssertNotEqual(pixelBuffer2, copiedPixelBuffer)
    returnedPixelBuffer = value.getPixelBufferRetained()
    XCTAssertEqual(copiedPixelBuffer, returnedPixelBuffer)
  }

  func testPerformanceNoCopy() {
    let value = _TextureValue()
    let pixelBuffer = createPixelBuffer()
    let pixelBuffer2 = createPixelBuffer()

    self.measure {
      for _ in 0..<1000 {
        value.storePixelBufferNoCopy(pixelBuffer)
        value.storePixelBufferNoCopy(pixelBuffer2)
      }
    }
  }

  func testPerformanceCopy() {
    let value = _TextureValue()
    let pixelBuffer = createPixelBuffer()
    let pixelBuffer2 = createPixelBuffer()

    self.measure {
      for _ in 0..<1000 {
        _ = value.storePixelBufferCopy(pixelBuffer)
        _ = value.storePixelBufferCopy(pixelBuffer2)
      }
    }
  }
}
