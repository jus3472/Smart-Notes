// FirestoreCodable.swift
import Foundation
import FirebaseFirestore

enum FirestoreEncoder {
    static func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = jsonObject as? [String: Any] else {
            throw NSError(domain: "FirestoreEncoder", code: -1, userInfo: nil)
        }
        return dict
    }
}

enum FirestoreDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from dict: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return try JSONDecoder().decode(T.self, from: data)
    }
}

