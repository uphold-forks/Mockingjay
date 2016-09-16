//
//  Matchers.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 28/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import URITemplate

// Collection of generic matchers

/// Mockingjay matcher which returns true for every request
public func everything(request:URLRequest) -> Bool {
  return true
}

/// Mockingjay matcher which matches URIs
public func uri(uri:String) -> (_ request:URLRequest) -> Bool {
  
  return { (request:URLRequest) in
    let template = URITemplate(template:uri)
    
    if let URLString = request.url?.absoluteString {
      if template.extract(URLString) != nil {
        return true
      }
    }
    
    if let path = request.url?.path {
      if template.extract(path) != nil {
        return true
      }
    }
    
    return false
  }
}

public enum HTTPMethod : CustomStringConvertible {
  case GET
  case POST
  case PATCH
  case PUT
  case DELETE
  case OPTIONS
  case HEAD
  
  public var description : String {
    switch self {
    case .GET:
      return "GET"
    case .POST:
      return "POST"
    case .PATCH:
      return "PATCH"
    case .PUT:
      return "PUT"
    case .DELETE:
      return "DELETE"
    case .OPTIONS:
      return "OPTIONS"
    case .HEAD:
      return "HEAD"
    }
  }
}

public func http(method:HTTPMethod, uri:String) -> (_ request:URLRequest) -> Bool {
  return { (request:URLRequest) in
    if let requestMethod = request.httpMethod {
      if requestMethod == method.description {
        return Mockingjay.uri(uri: uri)(request)
      }
    }
    
    return false
  }
}
