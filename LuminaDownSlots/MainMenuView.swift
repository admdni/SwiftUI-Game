import SwiftUI

// Rename this to match your project's UserProgress defined elsewhere
typealias GameProgress = UserProgress

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()
    @State private var showProfile = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                headerSection
                titleSection
                menuButtonsSection
                footerSection
            }
            .padding()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $viewModel.showGame) {
            CrystalFusionView(isTimeAttack: false)
        }
        .fullScreenCover(isPresented: $viewModel.showTimeAttack) {
            CrystalFusionView(isTimeAttack: true)
        }
        .sheet(isPresented: $viewModel.showTutorialView) {
            TutorialView()
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        HStack {
            MenuButton(
                icon: "person.fill",
                action: { showProfile = true }
            )
            
            Spacer()
            
            MenuButton(
                icon: "gearshape.fill",
                action: { showSettings = true }
            )
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("CRYSTAL")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text("FUSION")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(hex: "FF2E63"))
        }
        .shadow(color: Color(hex: "FF2E63").opacity(0.5), radius: 10)
    }
    
    private var menuButtonsSection: some View {
        VStack(spacing: 20) {
            MainMenuButton(
                title: "PLAY",
                subtitle: "Classic Mode",
                icon: "play.fill",
                action: viewModel.startGame
            )
            
            MainMenuButton(
                title: "TIME ATTACK",
                subtitle: "60 Seconds Challenge",
                icon: "clock.fill",
                action: viewModel.startTimeAttack
            )
            
            MainMenuButton(
                title: "TUTORIAL",
                subtitle: "Learn to Play",
                icon: "book.fill",
                action: viewModel.startTutorial
            )
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 15) {
            HighScoreDisplay(score: viewModel.highScore)
            SoundToggleButton(isSoundOn: $viewModel.isSoundOn)
        }
    }
}

// MARK: - Supporting Components
struct MenuButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

struct MainMenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct HighScoreDisplay: View {
    let score: Int
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
            
            Text("High Score: \(score)")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SoundToggleButton: View {
    @Binding var isSoundOn: Bool
    
    var body: some View {
        Button(action: { isSoundOn.toggle() }) {
            Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .foregroundColor(.white)
                .padding()
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - ViewModel
class MainMenuViewModel: ObservableObject {
    @Published var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
    @Published var isSoundOn: Bool = UserDefaults.standard.bool(forKey: "isSoundOn")
    @Published var showGame = false
    @Published var showTimeAttack = false
    @Published var showTutorialView = false
    
    func startGame() {
        showGame = true
    }
    
    func startTimeAttack() {
        showTimeAttack = true
    }
    
    func startTutorial() {
        showTutorialView = true
    }
}

// MARK: - Tutorial View
struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: dismissView) {
                        BackButton()
                    }
                    
                    Spacer()
                    
                    Text("HOW TO PLAY")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 30) {
                        TutorialStep(
                            icon: "hand.tap",
                            title: "Match Crystals",
                            description: "Tap matching crystals to create powerful combinations"
                        )
                        
                        TutorialStep(
                            icon: "sparkles",
                            title: "Create Fusions",
                            description: "Match 3 or more crystals to create higher-level fusions"
                        )
                        
                        TutorialStep(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Build Combos",
                            description: "Chain multiple matches to increase your score multiplier"
                        )
                        
                        TutorialStep(
                            icon: "crown.fill",
                            title: "Level Up",
                            description: "Reach high scores to unlock new crystal types and powers"
                        )
                    }
                    .padding()
                }
            }
        }
    }
}

struct TutorialStep: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(Color(hex: "FF2E63"))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .strokeBorder(Color(hex: "FF2E63").opacity(0.3), lineWidth: 1)
                        )
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MainMenuView()
}
