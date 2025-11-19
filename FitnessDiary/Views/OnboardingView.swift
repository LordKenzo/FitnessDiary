//
//  OnboardingView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    // Array di immagini per lo splash screen
    let onboardingImages = [
        "onboarding1", // Sostituisci con i nomi delle tue immagini
        "onboarding2",
        "onboarding3"
    ]

    @State private var currentIndex = 0
    @Binding var isPresented: Bool // Per chiudere lo splash screen

    var body: some View {
        ZStack {
            // TabView per lo swipe tra le immagini
            TabView(selection: $currentIndex) {
                ForEach(0..<onboardingImages.count, id: \.self) { index in
                    Image(onboardingImages[index])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentIndex)
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Indicatore dei cerchi
                HStack(spacing: 12) {
                    ForEach(0..<onboardingImages.count, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(currentIndex == index ? 1 : 0.45))
                            .frame(width: currentIndex == index ? 28 : 12, height: 10)
                    }
                }

                // Pulsante Skip
                Button(action: {
                    isPresented = false
                }) {
                    Text(localized: "onboarding.skip")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .appScreenBackground()
    }
}
