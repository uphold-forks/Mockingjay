//
//  MockingjayURLProtocolTests.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 28/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import Mockingjay


class MockingjayProtocolTests : XCTestCase {
  override func tearDown() {
    super.tearDown()
    MockingjayProtocol.removeAllStubs()
  }
  
  func testCannotInitWithUnknownRequest() {
    let request = URLRequest(url: URL(string: "https://kylefuller.co.uk/")!)
    let canInitWithRequest = MockingjayProtocol.canInit(with: request)
    
    XCTAssertFalse(canInitWithRequest)
  }
  
  func testCanInitWithKnownRequestUsingMatcher() {
    let request = URLRequest(url: URL(string: "https://kylefuller.co.uk/")!)
    
    _ = MockingjayProtocol.addStub(matcher: { (requestedRequest) -> (Bool) in
      return true
    }) { (request) -> (Response) in
      return Response.failure(NSError(domain: "MockingjayTests", code: 0, userInfo: nil))
    }
    
    let canInitWithRequest = MockingjayProtocol.canInit(with: request)
    
    XCTAssertTrue(canInitWithRequest)
  }
  
  func testProtocolReturnsErrorWithRegisteredStubError() {
    let request = URLRequest(url: URL(string: "https://kylefuller.co.uk/")!)
    let stubError = NSError(domain: "MockingjayTests", code: 0, userInfo: nil)
    
    _ = MockingjayProtocol.addStub(matcher: { _ in
      return true
    }) { (request) -> (Response) in
      return Response.failure(stubError)
    }
    
    var response:URLResponse?
    var error:NSError?
    var data: NSData? = nil
    do {
      data = try NSURLConnection.sendSynchronousRequest(request, returning: &response) as NSData?
    } catch let error1 as NSError {
      error = error1
    }
    
    XCTAssertNil(response)
    XCTAssertNil(data)
    XCTAssertEqual(error!.domain, "MockingjayTests")  }
  
  func testProtocolReturnsResponseWithRegisteredStubError() {
    let request = URLRequest(url: URL(string: "https://kylefuller.co.uk/")!)
    let stubResponse = URLResponse(url: request.url!, mimeType: "text/plain", expectedContentLength: 5, textEncodingName: "utf-8")
    let stubData = "Hello".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    
    _ = MockingjayProtocol.addStub(matcher: { (requestedRequest) -> (Bool) in
      return true
    }) { (request) -> (Response) in
      return Response.success(stubResponse, stubData)
    }
    
    var response:URLResponse?
    let data = try? NSURLConnection.sendSynchronousRequest(request, returning: &response)
    
    XCTAssertEqual(response?.url, stubResponse.url!)
    XCTAssertEqual(response?.textEncodingName, "utf-8")
    XCTAssertEqual(data, stubData)
  }
  
  func testProtocolReturnsResponseWithLastRegisteredMatchinbgStub() {
    let request = URLRequest(url: URL(string: "https://fuller.li/")!)
    let stubResponse = URLResponse(url: request.url!, mimeType: "text/plain", expectedContentLength: 6, textEncodingName: "utf-8")
    let stub1Data = "Stub 1".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    let stub2Data = "Stub 2".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    
    _ = MockingjayProtocol.addStub(matcher: { (requestedRequest) -> (Bool) in
      return true
    }) { (request) -> (Response) in
      return Response.success(stubResponse, stub1Data)
    }
    
    _ = MockingjayProtocol.addStub(matcher: { (requestedRequest) -> (Bool) in
      return true
    }) { (request) -> (Response) in
      return Response.success(stubResponse, stub2Data)
    }
    
    var response:URLResponse?
    let data = try? NSURLConnection.sendSynchronousRequest(request, returning: &response)
    
    XCTAssertEqual(response?.url, stubResponse.url!)
    XCTAssertEqual(response?.textEncodingName, "utf-8")
    XCTAssertEqual(data, stub2Data)
  }
  
}
