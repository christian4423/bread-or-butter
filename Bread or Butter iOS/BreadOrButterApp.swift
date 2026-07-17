//
//  BreadOrButterApp.swift
//  Bread or Butter (iOS companion)
//
//  Minimal iPhone companion for the watch app. It exists partly so the
//  standalone watch app can be distributed to the App Store (Xcode 26 can't
//  send a bare watch-only archive to the store), and it gives a friendly
//  explainer on the phone. The live fuel gauge lives on the Apple Watch.
//

import SwiftUI

@main
struct BreadOrButterApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneView()
        }
    }
}

struct PhoneView: View {
    private let butter = Color(red: 0.953, green: 0.792, blue: 0.376)
    private let bread = Color(red: 0.910, green: 0.604, blue: 0.235)

    var body: some View {
        ZStack {
            LinearGradient(colors: [butter.opacity(0.25), bread.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Bread or Butter")
                    .font(.largeTitle.bold())

                FuelRatioBar(fatFraction: 0.62)
                    .frame(height: 96)
                    .padding(.horizontal, 28)

                VStack(spacing: 6) {
                    Text("Are you burning butter or bread?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("As your heart rate rises, your body shifts from burning mostly fat (butter) to mostly carbs (bread). This app shows that live fuel mix as a playful gauge.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Label("Open Bread or Butter on your Apple Watch during a workout to see it live.",
                      systemImage: "applewatch")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Text("Estimate, not medical advice.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 12)
            }
        }
    }

}

#Preview {
    PhoneView()
}
