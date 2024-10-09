//
//  LaunchAppIntent.swift
//  Pápia
//
//  Created by Stef Kors on 08/10/2024.
//

import AppIntents

struct OpenPage: AppIntent, OpenIntent {
    static let title: LocalizedStringResource = "Open Page"


    @Parameter(title: "Target")
    var target: LaunchAppEnum


    func perform() async throws -> some IntentResult {
        //        NavigationModel.shared.navigate(to: target)
        
        return .result(opensIntent: OpenPage())
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Open Page...") // \(\.$trail)
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
