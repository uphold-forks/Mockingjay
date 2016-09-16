//
//  MockingjayTests.swift
//  MockingjayTests
//
//  Created by Kyle Fuller on 21/01/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import Mockingjay

func toString(item:AnyClass) -> String {
  return "\(item)"
}

class MockingjaySessionTests: XCTestCase {
  override func setUp() {
    super.setUp()
  }
  
  func testEphemeralSessionConfigurationIncludesProtocol() {
    let configuration = URLSessionConfiguration.ephemeral
    let protocolClasses = (configuration.protocolClasses!).map(toString)
    XCTAssertEqual(protocolClasses.first!, "MockingjayProtocol")
  }
  
  func testDefaultSessionConfigurationIncludesProtocol() {
    let configuration = URLSessionConfiguration.default
    let protocolClasses = (configuration.protocolClasses!).map(toString)
    XCTAssertEqual(protocolClasses.first!, "MockingjayProtocol")
  }
  
  func testURLSession() {
    let testExpectation = expectation(description: "MockingjaySessionTests")
    
    let stubbedError = NSError(domain: "Mockingjay Session Tests", code: 0, userInfo: nil)
    _ = stub(matcher: everything, builder: failure(error: stubbedError))
    
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    
    session.dataTask(with: URL(string: "https://httpbin.org/")!) { data, response, error in
      DispatchQueue.main.async() {
        XCTAssertNotNil(error)
        testExpectation.fulfill()
      }
      }.resume()
    
    waitForExpectations(timeout: 5) { error in
      XCTAssertNil(error, "\(error)")
    }
  }
}
