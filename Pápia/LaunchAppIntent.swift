//
//  LaunchAppIntent.swift
//  Pápia
//
//  Created by Stef Kors on 08/10/2024.
//

import AppIntents

struct OpenPage: AppIntent, OpenIntent {
    static let title: LocalizedStringResource = "Open Papia"


    @Parameter(title: "Target")
    var target: LaunchAppEnum

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result(opensIntent: OpenPage(target: .init(default: .home)))
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Open Page...") // \(\.$trail)
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



//struct LaunchAppIntent: AppIntent, OpenIntent  {
//    static var title: LocalizedStringResource = "Launch App"
//    @Parameter(title: "Target")
//    var target: LaunchAppEnum
//
////    func perform() async throws -> some OpensIntent {
////        // Code that performs the action...
////        print("running open intent")
//////        NavigationModel.shared.navigate(to: target)
////        return .result(opensIntent: LaunchAppIntent())
////    }
//
//}



enum LaunchAppEnum: String, AppEnum {
    // Target screens
    case home
    case history

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Pápia's app screens")
    static var caseDisplayRepresentations = [
        LaunchAppEnum.home : DisplayRepresentation("Home"),
        LaunchAppEnum.history : DisplayRepresentation("History")
    ]
}
