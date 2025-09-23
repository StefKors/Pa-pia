//
//  CodableAppStorage.swift
//  Pápia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

@propertyWrapper
public struct CodableAppStorage<Value: Codable>: DynamicProperty {
    @AppStorage private var value: Data

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var key: String

    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
        self.key = key

        do {
            let initialValue = try encoder.encode(wrappedValue)
            print("CODABLE \(key) init wrappedValue: \(wrappedValue)")
            self._value = AppStorage(wrappedValue: initialValue, key, store: store)
        } catch {
            print("CODABLE \(key) ERROR: \(error.localizedDescription) | fallback to empty data")
            self._value = AppStorage(wrappedValue: Data(), key, store: store)
        }
    }

    public var wrappedValue: Value {
        get {
            do {
                let result = try decoder.decode(Value.self, from: value)
                print("CODABLE \(key) wrappedValue: \(result)")
                return result
            } catch {
                print("CODABLE \(key) ERROR: \(error.localizedDescription) | fallback to force unwrap")
                return try! decoder.decode(Value.self, from: value)
            }
        }
        nonmutating set {
            do {
                let result = try encoder.encode(newValue)
                print("CODABLE \(key) setting: \(newValue)")
                value = result
            } catch {
                print("CODABLE \(key) ERROR: \(error.localizedDescription) | fallback to force unwrap")
                value = try! encoder.encode(newValue)
            }
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
