//
//  Widget_FactoryLiveActivity.swift
//  Widget Factory
//
//  Created by Ulises Islas on 19/02/25.
//
/*
import ActivityKit
import WidgetKit
import SwiftUI

struct Widget_FactoryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Widget_FactoryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Widget_FactoryAttributes.self) { context in
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

extension Widget_FactoryAttributes {
    fileprivate static var preview: Widget_FactoryAttributes {
        Widget_FactoryAttributes(name: "World")
    }
}

extension Widget_FactoryAttributes.ContentState {
    fileprivate static var smiley: Widget_FactoryAttributes.ContentState {
        Widget_FactoryAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Widget_FactoryAttributes.ContentState {
         Widget_FactoryAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Widget_FactoryAttributes.preview) {
   Widget_FactoryLiveActivity()
} contentStates: {
    Widget_FactoryAttributes.ContentState.smiley
    Widget_FactoryAttributes.ContentState.starEyes
}
*/
