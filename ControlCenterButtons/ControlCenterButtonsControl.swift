//
//  ControlCenterButtonsControl.swift
//  ControlCenterButtons
//
//  Created by Stef Kors on 08/10/2024.
//

import AppIntents
import SwiftUI
import WidgetKit


struct AppLaunchConfiguration: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Launch App"

    @Parameter(title: "Target")
    var target: LaunchAppEnum?
}


struct ControlCenterButtonsControl: ControlWidget {
    static let kind = "ControlCenterButtonsControlWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            intent: AppLaunchConfiguration.self
        ) { configuration in
            ControlWidgetButton(action: configuration) {
                Label(configuration.target?.rawValue ?? "open", systemImage: "bird.fill")
//                Image(systemName: configuration.target.glyph)
//                Text(configuration.target.name)
            }
        }
    }
}

struct OpenPageShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenPage(),
            phrases: [
                "Open page in \(.applicationName)",
                "Show page in \(.applicationName)"
            ],
            shortTitle: "Open page",
            systemImageName: "pin"
        )
    }
}

//struct TrailConditionsWidget: Widget {
//    static let kind = "TrailConditionsWidget"
//
//
//    var body: some WidgetConfiguration {
//        AppIntentConfiguration(
//            kind: Self.kind,
//            intent: AppLaunchConfiguration.self,
//            provider: OpenPageShortcut()
//        ) { _ in
//            Label("Search Pápia...", systemImage: "bird.fill")
//        }
//    }
//}

//struct ControlCenterButtonsControl: ControlWidget {
//    var body: some ControlWidgetConfiguration {
//
//        AppIntentControlConfiguration(
//            kind: "launchPapia",
//            intent: AppLaunchConfiguration.self
//        ) { configuration in
//            ControlWidgetButton(action: LaunchAppIntent()) {
//                Label("Search Pápia...", systemImage: "bird.fill")
//            }
//        }
//        .displayName("Launch Pápia with AppIntent")
//        .description("Quick Lookup with Pápia")
//
//    }
//}


//
//extension ControlCenterButtonsControl {
//    struct Provider: ControlValueProvider {
//        var previewValue: Bool {
//            false
//        }
//
//        func currentValue() async throws -> Bool {
//
//            return isRunning
//        }
//    }
//}
//
