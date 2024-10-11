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
        StaticControlConfiguration(
            kind: "com.stefkors.Pa-pia.performActionButton"
        ) {
            ControlWidgetButton(action: OpenPage(target: .init(default: .home))) {
                Label("Launch Papia", systemImage: "bird")
            }
        }
        .displayName("Perform Action")
        .description("An example control that performs an action.")
//    }
//        AppIntentControlConfiguration(
//            kind: Self.kind,
//            intent: AppLaunchConfiguration.self
//        ) { configuration in
//            ControlWidgetButton(action: OpenPage()) {
//                Label(configuration.target?.rawValue ?? "open", systemImage: "bird.fill")
//            }
//        }
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
