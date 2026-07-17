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

                gauge
                    .frame(height: 84)
                    .padding(.horizontal, 32)

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

    /// A static illustration of the butter/bread split with the knife divider.
    private var gauge: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let seam = w * 0.6
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: h * 0.14)
                        .fill(butter)
                        .frame(width: seam)
                    Capsule()
                        .fill(bread)
                        .frame(width: w - seam)
                }
                Capsule()
                    .fill(Color(white: 0.98))
                    .frame(width: max(6, w * 0.03), height: h * 0.96)
                    .position(x: seam, y: h / 2)
            }
        }
    }
}

#Preview {
    PhoneView()
}
