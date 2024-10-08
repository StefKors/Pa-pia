//
//  ControlCenterButtonsBundle.swift
//  ControlCenterButtons
//
//  Created by Stef Kors on 08/10/2024.
//

import WidgetKit
import SwiftUI

@main
struct ControlCenterButtonsBundle: WidgetBundle {
    var body: some Widget {
        ControlCenterButtons()
        ControlCenterButtonsControl()
        ControlCenterButtonsLiveActivity()
    }
}
