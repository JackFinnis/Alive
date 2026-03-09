//
//  Double.swift
//  Alive
//
//  Created by Jack Finnis on 29/05/2025.
//

extension Collection where Element == Double {
    func average() -> Element? {
        guard isNotEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
