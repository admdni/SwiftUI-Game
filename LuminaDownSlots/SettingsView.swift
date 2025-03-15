import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("playerName") var playerName: String = ""
    @AppStorage("isSoundOn") var isSoundOn: Bool = true
    @AppStorage("isMusicOn") var isMusicOn: Bool = true
    @AppStorage("isHapticsOn") var isHapticsOn: Bool = true
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 25) {
                // Header
                HStack {
                    Button(action: { dismissView() }) {
                        BackButton()
                    }
                    
                    Spacer()
                    
                    Text("SETTINGS")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                
                // Settings Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Player Name Section
                        SettingsSection(title: "PLAYER PROFILE") {
                            HStack {
                                Text("Player Name")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                TextField("Enter Name", text: $playerName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .frame(width: 150)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        // Sound Settings Section
                        SettingsSection(title: "SOUND & HAPTICS") {
                            SettingsToggle(title: "Sound Effects", isOn: $isSoundOn)
                            SettingsToggle(title: "Background Music", isOn: $isMusicOn)
                            SettingsToggle(title: "Haptic Feedback", isOn: $isHapticsOn)
                        }
                        
                        // About Section
                        SettingsSection(title: "ABOUT") {
                            VStack(alignment: .leading, spacing: 15) {
                                InfoRow(title: "Version", value: "4.3.0")
                                InfoRow(title: "Developer", value: "HAMMANI TECH")
                                InfoRow(title: "Contact", value: "info@hammanitech.com")
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "FF2E63"))
            
            content
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
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .foregroundColor(.white)
        }
        .toggleStyle(CustomToggleStyle())
    }
}

// Custom Toggle Style for iOS 14 compatibility
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color(hex: "FF2E63") : Color.gray.opacity(0.3))
                .frame(width: 50, height: 31)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SettingsView()
} 
