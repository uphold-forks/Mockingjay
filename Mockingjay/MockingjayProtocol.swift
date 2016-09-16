//
//  MockingjayProtocol.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 28/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation


/// Structure representing a registered stub
public struct Stub : Equatable {
  let matcher:Matcher
  let builder:Builder
  let uuid:NSUUID
  
  init(_ matcher: @escaping Matcher, builder: @escaping Builder) {
    self.matcher = matcher
    self.builder = builder
    uuid = NSUUID()
  }
}

public func ==(lhs:Stub, rhs:Stub) -> Bool {
  return lhs.uuid == rhs.uuid
}

var stubs = [Stub]()

public class MockingjayProtocol : URLProtocol {
  // MARK: Stubs
  private var enableDownloading = true
  private let operationQueue = OperationQueue()

  private static let onceToken: () = {
    URLProtocol.registerClass(MockingjayProtocol.self)
  }()

  class func addStub(stub:Stub) -> Stub {
    stubs.append(stub)
    
    _ = onceToken
    
    return stub
  }
  
  /// Register a matcher and a builder as a new stub
  public class func addStub(matcher: @escaping Matcher, builder: @escaping Builder) -> Stub {
    return addStub(stub: Stub(matcher, builder: builder))
  }
  
  /// Unregister the given stub
  public class func removeStub(stub:Stub) {
    if let index = stubs.index(of: stub) {
      stubs.remove(at: index)
    }
  }
  
  /// Remove all registered stubs
  public class func removeAllStubs() {
    stubs.removeAll(keepingCapacity: false)
  }
  
  /// Finds the appropriate stub for a request
  /// This method searches backwards though the registered requests
  /// to find the last registered stub that handles the request.
  class func stubForRequest(request:URLRequest) -> Stub? {
    for stub in stubs.reversed() {
      if stub.matcher(request) {
        return stub
      }
    }
    
    return nil
  }
  
  // MARK: NSURLProtocol
  
  /// Returns whether there is a registered stub handler for the given request.
  override public class func canInit(with request:URLRequest) -> Bool {
    return stubForRequest(request: request) != nil
  }
  
  override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  override public func stopLoading() {
    self.enableDownloading = false
    self.operationQueue.cancelAllOperations()
  }
  
  // MARK: Private Methods
  
  private func download(data:NSData?, inChunksOfBytes bytes:Int) {
    guard let data = data else {
      client?.urlProtocolDidFinishLoading(self)
      return
    }
    self.operationQueue.maxConcurrentOperationCount = 1
    self.operationQueue.addOperation { () -> Void in
      self.download(data: data, fromOffset: 0, withMaxLength: bytes)
    }
  }
  
  
  private func download(data:NSData, fromOffset offset:Int, withMaxLength maxLength:Int) {
    guard let queue = OperationQueue.current else {
      return
    }
    guard (offset < data.length) else {
      client?.urlProtocolDidFinishLoading(self)
      return
    }
    let length = min(data.length - offset, maxLength)
    
    queue.addOperation { () -> Void in
      guard self.enableDownloading else {
        self.enableDownloading = true
        return
      }
      
      let subdata = data.subdata(with: NSMakeRange(offset, length))
      self.client?.urlProtocol(self, didLoad: subdata)
      Thread.sleep(forTimeInterval: 0.01)
      self.download(data: data, fromOffset: offset + length, withMaxLength: maxLength)
    }
  }
  
  private func extractRangeFromHTTPHeaders(headers:[String : String]?) -> NSRange? {
    guard let rangeStr = headers?["Range"] else {
      return nil
    }
    let range = rangeStr.components(separatedBy: "=")[1].components(separatedBy: "-").map({ (str) -> Int in
      Int(str)!
    })
    let loc = range[0]
    let length = range[1] - loc + 1
    return NSMakeRange(loc, length)
  }
  
  private func applyRangeFromHTTPHeaders(
    headers:[String : String]?,
    toData data:inout NSData,
          andUpdateResponse response:inout URLResponse) {
    guard let range = extractRangeFromHTTPHeaders(headers: headers) else {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      return
    }
    let fullLength = data.length
    data = data.subdata(with: range) as NSData
    
    //Attach new headers to response
    if let r = response as? HTTPURLResponse {
      var header = r.allHeaderFields as! [String:String]
      header["Content-Length"] = String(data.length)
      header["Content-Range"] = String(range.httpRangeStringWithFullLength(fullLength: fullLength))
      response = HTTPURLResponse(url: r.url!, statusCode: r.statusCode, httpVersion: nil, headerFields: header)!
    }
    
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
  }
  
}

extension NSRange {
  func httpRangeStringWithFullLength(fullLength:Int) -> String {
    let endLoc = self.location + self.length - 1
    return "bytes " + String(self.location) + "-" + String(endLoc) + "/" + String(fullLength)
  }
}
