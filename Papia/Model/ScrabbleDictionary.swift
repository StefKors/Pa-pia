//
//  ScrabbleDictionary.swift
//  Pápia
//
//  Created by Stef Kors on 06/02/2026.
//

import Foundation

/// All available Scrabble word‑list editions that ship in the bundle.
///
/// The raw value is the filename (without extension) inside the
/// `scrabble/english` resource folder.
enum ScrabbleDictionary: String, CaseIterable, Identifiable, Codable {
    // MARK: – North‑American (NASPA)
    case nwl2023  = "NWL2023"
    case nwl2020  = "NWL2020"
    case nwl2018  = "NWL2018"
    case twl06    = "twl06"

    // MARK: – International / British (Collins)
    case csw21    = "CSW21"
    case csw19    = "CSW19"
    case csw15    = "CSW15"
    case sowpods  = "sowpods"

    var id: String { rawValue }

    /// Human‑readable label shown in the settings picker.
    var label: String {
        switch self {
        case .nwl2023: return "NWL 2023"
        case .nwl2020: return "NWL 2020"
        case .nwl2018: return "NWL 2018"
        case .twl06:   return "TWL06"
        case .csw21:   return "CSW21"
        case .csw19:   return "CSW19"
        case .csw15:   return "CSW15"
        case .sowpods: return "SOWPODS"
        }
    }

    /// Short description for the settings UI.
    var subtitle: String {
        switch self {
        case .nwl2023: return "NASPA Word List 2023 – latest NA tournament list"
        case .nwl2020: return "NASPA Word List 2020"
        case .nwl2018: return "NASPA Word List 2018"
        case .twl06:   return "Tournament Word List (legacy)"
        case .csw21:   return "Collins Scrabble Words 2021 – latest international list"
        case .csw19:   return "Collins Scrabble Words 2019"
        case .csw15:   return "Collins Scrabble Words 2015"
        case .sowpods: return "SOWPODS – classic international list"
        }
    }

    /// Group header in the picker.
    var region: ScrabbleDictionaryRegion {
        switch self {
        case .nwl2023, .nwl2020, .nwl2018, .twl06:
            return .northAmerican
        case .csw21, .csw19, .csw15, .sowpods:
            return .international
        }
    }

    /// The bundle resource name (matches the .txt filename without extension).
    var resourceName: String { rawValue }

    /// The default dictionary used when none has been chosen yet.
    static let `default`: ScrabbleDictionary = .nwl2023
}

/// Grouping for the picker sections.
enum ScrabbleDictionaryRegion: String, CaseIterable, Identifiable {
    case northAmerican = "North American"
    case international = "International"

    var id: String { rawValue }
}
