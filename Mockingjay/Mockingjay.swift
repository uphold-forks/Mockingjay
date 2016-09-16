//
//  Mockingjay.swift
//  Mockingjay
//
//  Created by Kyle Fuller on 28/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

public enum Response : Equatable {
  case success(URLResponse, Data?)
  case failure(Error)
}

public func ==(lhs:Response, rhs:Response) -> Bool {
  switch (lhs, rhs) {
  case let (.failure(lhsError), .failure(rhsError)):
    return lhsError._domain == rhsError._domain
  case let (.success(lhsResponse, lhsData), .success(rhsResponse, rhsData)):
    return lhsResponse == rhsResponse && lhsData == rhsData
  default:
    return false
  }
}

public typealias Matcher = (URLRequest) -> (Bool)
public typealias Builder = (URLRequest) -> (Response)
