import SwiftUI
import Foundation

struct TimeModeView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userProgress") private var userProgressData: Data = try! JSONEncoder().encode(UserProgress.empty)
    @State private var userProgress: UserProgress = .empty
    
    // Game States
    @State private var symbols: [[String]] = Array(repeating: Array(repeating: "🍎", count: 3), count: 3)
    @State private var spinning = false
    @State private var score = 0
    @State private var showGameOver = false
    @State private var comboMultiplier = 1
    @State private var lastWin = 0
    @State private var showWinAnimation = false
    @State private var timeRemaining: Double = 60.0 // Starting time
    @State private var timer: Timer?
    @State private var spinSpeed: Double = 1.0 // Base spin speed
    @State private var difficultyMultiplier: Double = 1.0
    
    // Time Mode specific states
    @State private var consecutiveWins = 0
    @State private var timeBonus: Double = 0
    @State private var showTimeBonus = false
    
    // Target score system
    @State private var targetScore: Int = 500
    @State private var currentLevel: Int = 1
    @State private var showLevelComplete = false
    @State private var bonusTimeAwarded: Double = 0
    
    let baseSymbols = ["🍎", "🍐", "🍊", "🍋"]
    let mediumSymbols = ["🍇", "🍓", "🍒", "🍑"]
    let hardSymbols = ["🥝", "🫐", "⭐️", "🌟"]
    let expertSymbols = ["💎", "7️⃣", "🎰", "🎲"]
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "2E0249"), Color(hex: "570A57")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: dismissView) {
                        BackButton()
                    }
                    
                    Spacer()
                    
                    // Target score display
                    VStack(spacing: 4) {
                        Text("Target: \(targetScore)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.yellow)
                        Text("Level \(currentLevel)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Timer display
                    ZStack {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 8)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(timeRemaining / 60.0))
                            .stroke(Color.red, lineWidth: 8)
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.1f", timeRemaining))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .progressViewStyle(CustomProgressStyle())
                    
                    Spacer()
                    
                    // Score
                    HStack {
                        Text("Score: \(score)")
                            .font(.title3)
                            .bold()
                        Text("/ \(targetScore)")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Progress to target
                ProgressView(value: Double(score), total: Double(targetScore))
                    .progressViewStyle(CustomProgressStyle())
                    .padding(.horizontal)
                
                // Slot machine
                VStack(spacing: 10) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<3) { column in
                           //     SlotSymbol(symbol: symbols[row][column], spinning: spinning)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .shadow(radius: 10)
                )
                
                // Combo and time bonus indicators
                if comboMultiplier > 1 {
                    Text("Combo x\(comboMultiplier)!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.yellow)
                }
                
                if showTimeBonus {
                    Text("+\(String(format: "%.1f", timeBonus))s")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                        .transition(.scale)
                }
                
                // Spin button
                Button(action: spin) {
                    Text("SPIN")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(spinning ? Color.gray : Color(hex: "FF2E63"))
                                .shadow(radius: 5)
                        )
                }
                .disabled(spinning || timeRemaining <= 0)
            }
            
            // Level Complete Overlay
            if showLevelComplete {
                LevelCompleteView(
                    level: currentLevel,
                    score: score,
                    bonusTime: bonusTimeAwarded,
                    onContinue: {
                        withAnimation {
                            showLevelComplete = false
                            currentLevel += 1
                            generateNewTarget()
                        }
                    }
                )
            }
            
            // Game Over overlay
            if showGameOver {
                TimeGameOverView(
                    score: score,
                    level: currentLevel,
                    dismiss: { dismissView() },
                    playAgain: resetGame
                )
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startGame() {
        loadUserProgress()
        resetGame()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 0.1
                if timeRemaining <= 0 {
                    gameOver()
                }
            }
        }
    }
    
    private func spin() {
        spinning = true
        spinSpeed = max(0.3, spinSpeed * 0.95) // Increase spin speed
        difficultyMultiplier += 0.1 // Increase difficulty
        
        // Get available symbols based on score
        var availableSymbols = baseSymbols
        if score > 1000 { availableSymbols += mediumSymbols }
        if score > 2500 { availableSymbols += hardSymbols }
        if score > 5000 { availableSymbols += expertSymbols }
        
        // Spin animation
        DispatchQueue.main.asyncAfter(deadline: .now() + spinSpeed) {
            for row in 0..<3 {
                for column in 0..<3 {
                    symbols[row][column] = availableSymbols.randomElement() ?? "🍎"
                }
            }
            spinning = false
            checkWin()
        }
    }
    
    private func checkWin() {
        var winAmount = 0
        var timeBonus: Double = 0
        
        // Check rows
        for row in symbols {
            if Set(row).count == 1 {
                winAmount += 100
                timeBonus += 2.0
            }
        }
        
        // Check columns
        for col in 0..<3 {
            if Set(symbols.map { $0[col] }).count == 1 {
                winAmount += 100
                timeBonus += 2.0
            }
        }
        
        // Check diagonals
        let diagonal1 = [symbols[0][0], symbols[1][1], symbols[2][2]]
        let diagonal2 = [symbols[0][2], symbols[1][1], symbols[2][0]]
        
        if Set(diagonal1).count == 1 {
            winAmount += 150
            timeBonus += 3.0
        }
        if Set(diagonal2).count == 1 {
            winAmount += 150
            timeBonus += 3.0
        }
        
        if winAmount > 0 {
            score += Int(Double(winAmount) * difficultyMultiplier)
            consecutiveWins += 1
            comboMultiplier = min(5, consecutiveWins)
            
            // Apply time bonus
            timeBonus *= Double(comboMultiplier)
            self.timeBonus = timeBonus
            timeRemaining = min(60.0, timeRemaining + timeBonus)
            
            withAnimation {
                showTimeBonus = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showTimeBonus = false
                }
            }
            
            // Check if target reached
            if score >= targetScore {
                levelComplete()
            }
        } else {
            consecutiveWins = 0
            comboMultiplier = 1
        }
    }
    
    private func levelComplete() {
        timer?.invalidate() // Pause timer
        withAnimation {
            showLevelComplete = true
        }
        
        // Add bonus time
        timeRemaining += bonusTimeAwarded
        
        // Update progress
        var progress = userProgress
        //progress.timeModeBestLevel = max(progress.timeModeBestLevel, currentLevel)
        if let encoded = try? JSONEncoder().encode(progress) {
            userProgressData = encoded
        }
    }
    
    private func gameOver() {
        timer?.invalidate()
        
        // Update user progress
        var progress = userProgress
       // progress.timeModeBestScore = max(progress.timeModeBestScore, score)
     //   progress.timeModeGamesPlayed += 1
        
        if let encoded = try? JSONEncoder().encode(progress) {
            userProgressData = encoded
        }
        
        withAnimation {
            showGameOver = true
        }
    }
    
    private func resetGame() {
        currentLevel = 1
        generateNewTarget()
        score = 0
        timeRemaining = 60.0
        spinSpeed = 1.0
        difficultyMultiplier = 1.0
        comboMultiplier = 1
        consecutiveWins = 0
        showGameOver = false
        showLevelComplete = false
        
        // Reset symbols
        for row in 0..<3 {
            for column in 0..<3 {
                symbols[row][column] = baseSymbols.randomElement() ?? "🍎"
            }
        }
        
        startTimer()
    }
    
    private func loadUserProgress() {
        if let decoded = try? JSONDecoder().decode(UserProgress.self, from: userProgressData) {
            userProgress = decoded
        }
    }
    
    private func generateNewTarget() {
        // Increase target based on level
        targetScore = 500 * currentLevel + Int(Double(currentLevel) * 250.0 * Double.random(in: 0.8...1.2))
        bonusTimeAwarded = min(20.0, 10.0 + Double(currentLevel) * 2.0) // More bonus time for higher levels
    }
}

struct TimeGameOverView: View {
    let score: Int
    let level: Int
    let dismiss: () -> Void
    let playAgain: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Game Over!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Text("Level \(level)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Final Score: \(score)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    Button(action: dismiss) {
                        Text("Exit")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(25)
                    }
                    
                    Button(action: playAgain) {
                        Text("Play Again")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color(hex: "FF2E63"))
                            .cornerRadius(25)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .shadow(radius: 10)
            )
        }
    }
}

// Level Complete View
struct LevelCompleteView: View {
    let level: Int
    let score: Int
    let bonusTime: Double
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Level Complete!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.yellow)
                
                VStack(spacing: 10) {
                    Text("Level \(level) Cleared!")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Score: \(score)")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("+\(String(format: "%.1f", bonusTime))s Bonus Time!")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .padding()
                
                Button(action: onContinue) {
                    Text("Continue to Level \(level + 1)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 250, height: 60)
                        .background(Color(hex: "FF2E63"))
                        .cornerRadius(30)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .shadow(radius: 10)
            )
        }
        .transition(.opacity)
    }
}

// Custom Progress Style
struct CustomProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF2E63"), Color(hex: "7E1DC3")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0))
                    .frame(height: 8)
            }
        }
    }
} 
