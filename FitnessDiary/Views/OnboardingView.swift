//
//  OnboardingView.swift
//  FitnessDiary
//
//  Created by Lorenzo Franceschini on 16/11/25.
//


import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    let onboardingImages = [
        "onboarding1",
        "onboarding2",
        "onboarding3"
    ]
    
    @State private var currentIndex = 0
    @Binding var isPresented: Bool
    
    var body: some View {
        AppBackgroundView {
            ZStack {
                // TabView per lo swipe tra le immagini
                TabView(selection: $currentIndex) {
                    ForEach(0..<onboardingImages.count, id: \.self) { index in
                        Image(onboardingImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // Indicatore dei cerchi e pulsante Skip
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ForEach(0..<onboardingImages.count, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(currentIndex == index ? 1 : 0.45))
                                .frame(width: currentIndex == index ? 28 : 12, height: 10)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(localized: "onboarding.skip")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
    }

}

