//
//  CodableAppStorage.swift
//  Papia
//
//  Created by Stef Kors on 23/09/2025.
//


import SwiftUI

@propertyWrapper
public struct CodableAppStorage<Value: Codable>: DynamicProperty {
    @AppStorage private var value: Data

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let defaultValue: Value

    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
        self.defaultValue = wrappedValue
        let initialValue = (try? encoder.encode(wrappedValue)) ?? Data()
        self._value = AppStorage(wrappedValue: initialValue, key, store: store)
    }

    public var wrappedValue: Value {
        get {
            // If the stored data can't be decoded (e.g. the type changed
            // between app versions), fall back to the default value and
            // silently reset the persisted data so subsequent reads succeed.
            if let decoded = try? decoder.decode(Value.self, from: value) {
                return decoded
            }
            // Reset corrupted data to the default
            if let resetData = try? encoder.encode(defaultValue) {
                value = resetData
            }
            return defaultValue
        }
        nonmutating set {
            if let encoded = try? encoder.encode(newValue) {
                value = encoded
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
