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

    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
        do {
            let initialValue = try encoder.encode(wrappedValue)
            self._value = AppStorage(wrappedValue: initialValue, key, store: store)
        } catch {
            self._value = AppStorage(wrappedValue: Data(), key, store: store)
        }
    }

    public var wrappedValue: Value {
        get {
            do {
                return try decoder.decode(Value.self, from: value)
            } catch {
                return try! decoder.decode(Value.self, from: value)
            }
        }
        nonmutating set {
            do {
                value = try encoder.encode(newValue)
            } catch {
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
