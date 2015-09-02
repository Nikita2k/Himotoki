//
//  Extractor.swift
//  Himotoki
//
//  Created by Syo Ikeda on 5/2/15.
//  Copyright (c) 2015 Syo Ikeda. All rights reserved.
//

public struct Extractor {
    public let rawValue: AnyObject

    internal init(_ rawValue: AnyObject) {
        self.rawValue = rawValue
    }

    private func rawValue(keyPath: KeyPath) throws -> AnyObject? {
        typealias Expected = [String: AnyObject]

        guard let dictionary = rawValue as? Expected else {
            throw DecodingError.TypeMismatch(
                keyPath: keyPath,
                object: rawValue,
                expected: Expected.self,
                actual: rawValue.dynamicType as Any.Type
            )
        }

        let components = ArraySlice(keyPath.components)
        return valueFor(components, dictionary)
    }

    /// - Throws: DecodingError
    public func value<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> T {
        guard let value: T = try valueOptional(keyPath) else {
            throw DecodingError.MissingKeyPath(keyPath)
        }

        return value
    }

    /// - Throws: DecodingError
    public func valueOptional<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> T? {
        do {
            return try rawValue(keyPath).map(decode)
        } catch let DecodingError.TypeMismatch(_, object, expected, actual) {
            throw DecodingError.TypeMismatch(keyPath: keyPath, object: object, expected: expected, actual: actual)
        }
    }

    /// - Throws: DecodingError
    public func array<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> [T] {
        guard let array: [T] = try arrayOptional(keyPath) else {
            throw DecodingError.MissingKeyPath(keyPath)
        }

        return array
    }

    /// - Throws: DecodingError
    public func arrayOptional<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> [T]? {
        return try rawValue(keyPath).map(decodeArray)
    }

    /// - Throws: DecodingError
    public func dictionary<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> [String: T] {
        guard let dictionary: [String: T] = try dictionaryOptional(keyPath) else {
            throw DecodingError.MissingKeyPath(keyPath)
        }

        return dictionary
    }

    /// - Throws: DecodingError
    public func dictionaryOptional<T: Decodable where T.DecodedType == T>(keyPath: KeyPath) throws -> [String: T]? {
        return try rawValue(keyPath).map(decodeDictionary)
    }
}

extension Extractor: Decodable {
    public static func decode(e: Extractor) throws -> Extractor {
        return e
    }
}

// Implement it as a tail recursive function.
//
// `ArraySlice` is used for performance optimization.
// See https://gist.github.com/norio-nomura/d9ec7212f2cfde3fb662.
private func valueFor(keyPathComponents: ArraySlice<String>, _ dictionary: [String: AnyObject]) -> AnyObject? {
    guard let first = keyPathComponents.first else {
        return nil
    }

    guard let object = dictionary[first] else {
        return nil
    }

    switch object {
    case is NSNull:
        return nil

    case let dict as [String: AnyObject] where keyPathComponents.count > 1:
        let tail = keyPathComponents.dropFirst()
        return valueFor(tail, dict)

    default:
        return object
    }
}
