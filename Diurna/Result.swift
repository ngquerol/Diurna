//
//  Result.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/08/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

enum Result<T, E: Error> {
    case success(T)
    case failure(E)

    init(_ optionalValue: T?, failWith error: E) {
        self = optionalValue.map(Result.success) ?? .failure(error)
    }

    init( _ throwing: () throws -> T) {
        do {
            self = .success(try throwing())
        } catch {
            self = .failure(error as! E)
        }
    }

    var value: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }

    var error: E? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }

    var isError: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }

    func map<U>(_ transform: (T) -> U) -> Result<U, E> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .failure(let error): return .failure(error)
        }
    }

    func flatMap<U>(_ transform: (T) -> Result<U, E>) -> Result<U, E> {
        switch self {
        case .success(let value): return transform(value)
        case .failure(let error): return .failure(error)
        }
    }
}

extension Result: CustomStringConvertible {
    var description: String {
        switch self {
        case .success(let value): return ".success(\(value))"
        case .failure(let error): return ".failure(\(error))"
        }
    }
}

extension Result: CustomDebugStringConvertible {
    var debugDescription: String { return description }
}
