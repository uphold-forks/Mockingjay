//
//  XCTest.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 28/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import ObjectiveC
import XCTest

var AssociatedMockingjayRemoveStubOnTearDownHandle: UInt8 = 0
extension XCTest {
  private static let mockingjayTearDownSwizzleToken: () = {
    let tearDown = class_getInstanceMethod(XCTest.self, #selector(XCTest.tearDown))
    let mockingjayTearDown = class_getInstanceMethod(XCTest.self, #selector(XCTest.mockingjayTearDown))
    method_exchangeImplementations(tearDown, mockingjayTearDown)
  }()

  // MARK: Stubbing
  
  /// Whether Mockingjay should remove stubs on teardown
  public var mockingjayRemoveStubOnTearDown: Bool {
    get {
      let associatedResult = objc_getAssociatedObject(self, &AssociatedMockingjayRemoveStubOnTearDownHandle) as? Bool
      return associatedResult ?? true
    }
    
    set {
      objc_setAssociatedObject(self, &AssociatedMockingjayRemoveStubOnTearDownHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public func stub(matcher:@escaping Matcher, builder:@escaping Builder) -> Stub {
    if mockingjayRemoveStubOnTearDown {
      XCTest.mockingjaySwizzleTearDown()
    }
    
    return MockingjayProtocol.addStub(matcher: matcher, builder: builder)
  }
  
  public func removeStub(stub:Stub) {
    MockingjayProtocol.removeStub(stub: stub)
  }
  
  public func removeAllStubs() {
    MockingjayProtocol.removeAllStubs()
  }
  
  // MARK: Teardown
  
  public class func mockingjaySwizzleTearDown() {
    _ = mockingjayTearDownSwizzleToken
  }
  
  func mockingjayTearDown() {
    mockingjayTearDown()
    
    if mockingjayRemoveStubOnTearDown {
      MockingjayProtocol.removeAllStubs()
    }
  }
}
