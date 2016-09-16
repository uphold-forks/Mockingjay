//
//  NSURLSessionConfiguration.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 01/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

//var mockingjaySessionSwizzleToken: dispatch_once_t = 0

extension URLSessionConfiguration {
   private static let mockingjaySessionSwizzleToken: () = {
    let defaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
    let mockingjayDefaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.mockingjayDefaultSessionConfiguration))
    method_exchangeImplementations(defaultSessionConfiguration, mockingjayDefaultSessionConfiguration)
    
    let ephemeralSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.ephemeral))
    let mockingjayEphemeralSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.mockingjayEphemeralSessionConfiguration))
    method_exchangeImplementations(ephemeralSessionConfiguration, mockingjayEphemeralSessionConfiguration)
  }()

  /// Swizzles NSURLSessionConfiguration's default and ephermeral sessions to add Mockingjay
  public class func mockingjaySwizzleDefaultSessionConfiguration() {
    _ = mockingjaySessionSwizzleToken
  }
  
  class func mockingjayDefaultSessionConfiguration() -> URLSessionConfiguration {
    let configuration = mockingjayDefaultSessionConfiguration()
    configuration.protocolClasses = [MockingjayProtocol.self] as [AnyClass] + configuration.protocolClasses!
    return configuration
  }
  
  class func mockingjayEphemeralSessionConfiguration() -> URLSessionConfiguration {
    let configuration = mockingjayEphemeralSessionConfiguration()
    configuration.protocolClasses = [MockingjayProtocol.self] as [AnyClass] + configuration.protocolClasses!
    return configuration
  }
}
