//
//  ControlCenterButtonsLiveActivity.swift
//  ControlCenterButtons
//
//  Created by Stef Kors on 08/10/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ControlCenterButtonsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ControlCenterButtonsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ControlCenterButtonsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ControlCenterButtonsAttributes {
    fileprivate static var preview: ControlCenterButtonsAttributes {
        ControlCenterButtonsAttributes(name: "World")
    }
}

extension ControlCenterButtonsAttributes.ContentState {
    fileprivate static var smiley: ControlCenterButtonsAttributes.ContentState {
        ControlCenterButtonsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ControlCenterButtonsAttributes.ContentState {
         ControlCenterButtonsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ControlCenterButtonsAttributes.preview) {
   ControlCenterButtonsLiveActivity()
} contentStates: {
    ControlCenterButtonsAttributes.ContentState.smiley
    ControlCenterButtonsAttributes.ContentState.starEyes
}
