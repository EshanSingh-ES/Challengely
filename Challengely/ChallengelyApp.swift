//
//  ChallengelyApp.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct ChallengelyApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppFeature.State(),
                    reducer: { AppFeature() }
                )
            )
        }
    }
}
