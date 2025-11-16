//
//  OnboardingView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI

struct OnboardingView: View {
    // Array di immagini per lo splash screen
    let onboardingImages = [
        "onboarding1", // Sostituisci con i nomi delle tue immagini
        "onboarding2",
        "onboarding3"
    ]

    @State private var currentIndex = 0
    @Binding var isPresented: Bool // Per chiudere lo splash screen

    var body: some View {
        VStack {
            // TabView per lo swipe tra le immagini
            TabView(selection: $currentIndex) {
                ForEach(0..<onboardingImages.count, id: \.self) { index in
                    Image(onboardingImages[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentIndex)


            // Indicatore dei cerchi
            HStack(spacing: 8) {
                ForEach(0..<onboardingImages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentIndex == index ? Color.blue : Color.gray)
                        .frame(width: currentIndex == index ? 20 : 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            // Pulsante Skip
            Button(action: {
                isPresented = false
            }) {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }
}
