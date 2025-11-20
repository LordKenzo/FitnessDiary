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
                        ZStack {
                            Image(onboardingImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .contentShape(Rectangle())
                                .ignoresSafeArea()
                            
                            // Mostra il pulsante FITTYPAL solo sull'ultima pagina
                            if index == onboardingImages.count - 1 {
                                VStack {
                                    Spacer()
                                    Button(action: {
                                        isPresented = false
                                    }) {
                                        Text("FITTYPAL")
                                            .font(.largeTitle.weight(.bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 40)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.blue)
                                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                            )
                                    }
                                    .padding(.bottom, 100)
                                }
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // Indicatore dei cerchi
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ForEach(0..<onboardingImages.count, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(currentIndex == index ? 1 : 0.45))
                                .frame(width: currentIndex == index ? 28 : 12, height: 10)
                                .onTapGesture {
                                    currentIndex = index
                                }
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Mostra il pulsante Skip solo se non siamo all'ultima immagine
                    if currentIndex < onboardingImages.count - 1 {
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
}
