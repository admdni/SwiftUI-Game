import SwiftUI
import Foundation

struct ChallengeModeView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userProgress") private var userProgressData: Data = try! JSONEncoder().encode(UserProgress.empty)
    @State private var userProgress: UserProgress = .empty
    
    // Game States
    @State private var symbols: [[String]] = Array(repeating: Array(repeating: "🍎", count: 3), count: 3)
    @State private var spinning = false
    @State private var score = 0
    @State private var timeRemaining: Double = 30.0
    @State private var timer: Timer?
    @State private var showGameOver = false
    @State private var currentChallenge: Challenge?
    @State private var showChallengeModal = false
    @State private var challengesCompleted = 0
    @State private var consecutiveWins = 0
    
    // Challenge specific states
    @State private var targetScore: Int = 0
    @State private var requiredMatches: Int = 0
    @State private var matchesAchieved: Int = 0
    @State private var challengeTimeLimit: Double = 30.0
    
    struct Challenge {
        let type: ChallengeType
        let description: String
        let target: Int
        let timeLimit: Double
        let difficulty: Int
        
        enum ChallengeType: CaseIterable {
            case score
            case matches
            case combo
            case time
            case hybrid
        }
    }
    
    let challenges: [Challenge.ChallengeType: [String]] = [
        .score: [
            "Score %d points in %d seconds",
            "Reach %d points without losing combo",
            "Get to %d points with special symbols"
        ],
        .matches: [
            "Get %d diagonal matches",
            "Complete %d horizontal matches",
            "Make %d matches with special symbols"
        ],
        .combo: [
            "Maintain a %dx combo for %d seconds",
            "Reach a %dx combo multiplier",
            "Get %d consecutive wins"
        ],
        .time: [
            "Survive for %d seconds",
            "Score %d points in %d seconds",
            "Get %d matches in %d seconds"
        ],
        .hybrid: [
            "Score %d points and get %d matches",
            "Reach %dx combo and score %d points",
            "Complete %d matches in %d seconds"
        ]
    ]
    
    private func generateNewChallenge() {
        let types = Challenge.ChallengeType.allCases
        let randomType = types.randomElement()!
        let difficulty = challengesCompleted / 5 + 1 // Increases every 5 challenges
        
        var target = 0
        var timeLimit = 30.0
        var description = ""
        
        switch randomType {
        case .score:
            target = 500 * difficulty
            timeLimit = Double(30 + difficulty * 5)
            description = String(format: challenges[.score]!.randomElement()!, target, Int(timeLimit))
        case .matches:
            target = 3 + difficulty
            timeLimit = Double(20 + difficulty * 3)
            description = String(format: challenges[.matches]!.randomElement()!, target)
        case .combo:
            target = 2 + difficulty
            timeLimit = Double(25 + difficulty * 4)
            description = String(format: challenges[.combo]!.randomElement()!, target, Int(timeLimit))
        case .time:
            target = difficulty * 10
            timeLimit = Double(15 + difficulty * 5)
            description = String(format: challenges[.time]!.randomElement()!, Int(timeLimit))
        case .hybrid:
            target = 300 * difficulty
            let secondaryTarget = 2 + difficulty
            timeLimit = Double(35 + difficulty * 6)
            description = String(format: challenges[.hybrid]!.randomElement()!, target, secondaryTarget)
        }
        
        currentChallenge = Challenge(
            type: randomType,
            description: description,
            target: target,
            timeLimit: timeLimit,
            difficulty: difficulty
        )
        
        timeRemaining = timeLimit
        showChallengeModal = true
    }
    
    private func getProgressForCurrentChallenge() -> Double {
        guard let challenge = currentChallenge else { return 0 }
        
        switch challenge.type {
        case .score:
            return Double(score) / Double(challenge.target)
        case .matches:
            return Double(matchesAchieved) / Double(challenge.target)
        case .combo:
            return Double(consecutiveWins) / Double(challenge.target)
        case .time:
            return timeRemaining / challenge.timeLimit
        case .hybrid:
            // For hybrid, use the average of both conditions
            let scoreProgress = Double(score) / Double(challenge.target)
            let matchProgress = Double(matchesAchieved) / Double(requiredMatches)
            return (scoreProgress + matchProgress) / 2.0
        }
    }
    
    private func spin() {
        guard !spinning else { return }
        
        spinning = true
        
        // Randomize symbols
        for row in 0..<3 {
            for column in 0..<3 {
                let availableSymbols = getSymbolsForDifficulty(currentChallenge?.difficulty ?? 1)
                symbols[row][column] = availableSymbols.randomElement() ?? "🍎"
            }
        }
        
        // Check for matches after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkMatches()
            spinning = false
        }
    }
    
    private func getSymbolsForDifficulty(_ difficulty: Int) -> [String] {
        var symbols = ["🍎", "🍐", "🍊", "🍋"]
        if difficulty > 2 { symbols += ["🍇", "🍓"] }
        if difficulty > 4 { symbols += ["🍒", "🍑"] }
        if difficulty > 6 { symbols += ["💎", "⭐️"] }
        return symbols
    }
    
    private func checkMatches() {
        var matches = 0
        
        // Check rows
        for row in 0..<3 {
            if symbols[row][0] == symbols[row][1] && symbols[row][1] == symbols[row][2] {
                matches += 1
            }
        }
        
        // Check columns
        for col in 0..<3 {
            if symbols[0][col] == symbols[1][col] && symbols[1][col] == symbols[2][col] {
                matches += 1
            }
        }
        
        // Check diagonals
        if symbols[0][0] == symbols[1][1] && symbols[1][1] == symbols[2][2] {
            matches += 1
        }
        if symbols[0][2] == symbols[1][1] && symbols[1][1] == symbols[2][0] {
            matches += 1
        }
        
        if matches > 0 {
            score += matches * 100 * (currentChallenge?.difficulty ?? 1)
            matchesAchieved += matches
            consecutiveWins += 1
            checkChallengeCompletion()
        } else {
            consecutiveWins = 0
        }
    }
    
    private func startChallenge() {
        timeRemaining = currentChallenge?.timeLimit ?? 30.0
        score = 0
        matchesAchieved = 0
        consecutiveWins = 0
        
        // Start the timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                checkChallengeCompletion()
            }
        }
    }
    
    private func checkChallengeCompletion() {
        guard let challenge = currentChallenge else { return }
        
        let completed = switch challenge.type {
        case .score:
            score >= challenge.target
        case .matches:
            matchesAchieved >= challenge.target
        case .combo:
            consecutiveWins >= challenge.target
        case .time:
            timeRemaining <= 0
        case .hybrid:
            score >= challenge.target && matchesAchieved >= requiredMatches
        }
        
        if completed {
            timer?.invalidate()
            challengesCompleted += 1
            
            // Update user progress
            var progress = userProgress
       //     progress.challengesCompleted += 1
          //  progress.challengeBestStreak = max(progress.challengeBestStreak, challengesCompleted)
           // progress.challengeHighestDifficulty = max(progress.challengeHighestDifficulty, challenge.difficulty)
           // progress.challengeTotalScore += score
            
            if let encoded = try? JSONEncoder().encode(progress) {
                userProgressData = encoded
            }
            
            // Generate next challenge
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                generateNewChallenge()
            }
        }
    }
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
                    
                    // Challenge counter
                    Text("Challenge #\(challengesCompleted + 1)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Timer
                    Text(String(format: "%.1f", timeRemaining))
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding()
                
                // Current challenge info
                if let challenge = currentChallenge {
                    VStack(spacing: 5) {
                        Text(challenge.description)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        ProgressView(value: getProgressForCurrentChallenge())
                            .progressViewStyle(CustomProgressStyle())
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
                }
                
                // Slot machine
                VStack(spacing: 10) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<3) { column in
                         //       SlotSymbol(symbol: symbols[row][column], spinning: spinning)
                            }
                        }
                    }
                }
                .padding()
                
                // Score and stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score: \(score)")
                        Text("Matches: \(matchesAchieved)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spin button
                    Button(action: spin) {
                        Text("SPIN")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(spinning ? Color.gray : Color(hex: "FF2E63"))
                            .cornerRadius(25)
                    }
                    .disabled(spinning)
                }
                .padding()
            }
        }
        .onAppear {
            generateNewChallenge()
        }
        .sheet(isPresented: $showChallengeModal) {
            ChallengeModalView(challenge: currentChallenge!, onStart: startChallenge)
        }
    }
}

struct ChallengeModalView: View {
    @Environment(\.presentationMode) var presentationMode
    let challenge: ChallengeModeView.Challenge
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "2E0249").opacity(0.98)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("New Challenge!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mission:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(challenge.description)
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Time Limit: \(Int(challenge.timeLimit))s")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Difficulty: \(String(repeating: "⭐️", count: challenge.difficulty))")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onStart()
                }) {
                    Text("Start Challenge")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "FF2E63"))
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .frame(maxHeight: 400)
    }
}

struct ChallengeCompleteView: View {
    @Environment(\.presentationMode) var presentationMode
    let score: Int
    let challenge: ChallengeModeView.Challenge
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Challenge Complete!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.yellow)
                
                VStack(spacing: 15) {
                    Text("Score: \(score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Difficulty: \(String(repeating: "⭐️", count: challenge.difficulty))")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                
                Button(action: {
                    onNext()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Next Challenge")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color(hex: "FF2E63"))
                        .cornerRadius(25)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
} 
