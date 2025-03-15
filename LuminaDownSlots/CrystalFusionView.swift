import SwiftUI
import Foundation

struct CrystalFusionView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userProgress") private var userProgressData: Data = try! JSONEncoder().encode(UserProgress.empty)
    @State private var userProgress: UserProgress = .empty
    let isTimeAttack: Bool
    
    // Game States
    @State private var crystals: [[Crystal]] = Array(repeating: Array(repeating: Crystal.random(level: 1), count: 3), count: 3)
    @State private var isFusing = false
    @State private var score = 0
    @State private var fusionPower = 1
    @State private var lastFusion = 0
    @State private var showFusionAnimation = false
    @State private var showPowerUpAnimation = false
    @State private var phase = 0.0
    @State private var isAnimating = false
    @State private var selectedCrystals: [(row: Int, column: Int)] = []
    @State private var showTutorial = false
    @State private var comboMultiplier = 1
    @State private var showComboText = false
    @State private var gameTime = 60
    @State private var isGameActive = true
    @State private var showGameOver = false
    @State private var pulsingCrystals: Set<String> = []
    @State private var fusionParticles: [FusionParticle] = []
    @State private var showQuiz = false
    @State private var successfulMatches = 0
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Crystal Definitions
    struct Crystal: Equatable, Identifiable {
        let id = UUID()
        let emoji: String
        let type: CrystalType
        let rarity: CrystalRarity
        var power: Int
        var position: CGPoint
        var isSelected: Bool = false
        var animation: Bool = false
        
        static func == (lhs: Crystal, rhs: Crystal) -> Bool {
            return lhs.type == rhs.type && lhs.rarity == rhs.rarity
        }
        
        static func random(level: Int) -> Crystal {
            // Calculate rarity
            let (rarity, type) = calculateRarityAndType(level: level)
            
            // Get emoji and power
            let emoji = getCrystalEmoji(type: type, rarity: rarity)
            let power = getPower(rarity: rarity)
            
            // Create crystal
            return Crystal(
                emoji: emoji,
                type: type,
                rarity: rarity,
                power: power,
                position: CGPoint(x: 0, y: 0)
            )
        }
        
        private static func calculateRarityAndType(level: Int) -> (CrystalRarity, CrystalType) {
            let random = Int.random(in: 1...100)
            
            // Rarity chances increase with level
            let epicChance = min(5 + level, 20)
            let rareChance = min(20 + level, 40)
            
            let rarity: CrystalRarity
            if random <= epicChance {
                rarity = .epic
            } else if random <= rareChance + epicChance {
                rarity = .rare
            } else {
                rarity = .common
            }
            
            // Select random type
            let type = CrystalType.allCases.randomElement()!
            
            return (rarity, type)
        }
        
        static func getCrystalEmoji(type: CrystalType, rarity: CrystalRarity) -> String {
            switch (type, rarity) {
            case (.fire, .common): return "🔴"
            case (.fire, .rare): return "🔥"
            case (.fire, .epic): return "💥"
                
            case (.water, .common): return "🔵"
            case (.water, .rare): return "💧"
            case (.water, .epic): return "🌊"
                
            case (.earth, .common): return "🟢"
            case (.earth, .rare): return "🌳"
            case (.earth, .epic): return "🌍"
                
            case (.air, .common): return "⚪️"
            case (.air, .rare): return "💨"
            case (.air, .epic): return "🌪️"
                
            case (.energy, .common): return "🟡"
            case (.energy, .rare): return "⚡️"
            case (.energy, .epic): return "✨"
            }
        }
        
        static func getPower(rarity: CrystalRarity) -> Int {
            switch rarity {
            case .common: return 1
            case .rare: return 3
            case .epic: return 5
            }
        }
    }
    
    enum CrystalType: CaseIterable {
        case fire, water, earth, air, energy
    }
    
    enum CrystalRarity {
        case common, rare, epic
    }
    
    // Fusion Particle Effect
    struct FusionParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
        var emoji: String
    }
    
    // Fusion Effects
    let fusionEffects = [
        "✨", // Sparkles
        "💥", // Explosion
        "🌈", // Rainbow
        "⚡️", // Energy
        "🔮", // Magic
        "🌟"  // Star
    ]
    
    // Crystal arrays for different rarities
    private let basicCrystals = ["🔴", "🔵", "🟢", "⚪️", "🟡"]
    private let rareCrystals = ["🔥", "💧", "🌳", "💨", "⚡️"]
    private let epicCrystals = ["💥", "🌊", "🌍", "🌪️", "✨"]
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            VStack(spacing: 20) {
                headerSection
                
                Spacer()
                
                crystalGridSection
                
                Spacer()
                
                actionButtonsSection
            }
            .padding()
            
            overlayElements
        }
        .onAppear(perform: setupGame)
        .onReceive(timer, perform: updateGameTimer)
        .sheet(isPresented: $showQuiz) {
            QuizView { isCorrect in
                if isCorrect {
                    score += 1000
                    fusionPower += 1
                    showPowerUpAnimation = true
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundLayer: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            CrystalGridBackgroundView()
        }
    }
    
    private var headerSection: some View {
        GameHeaderView(
            score: score,
            fusionPower: fusionPower,
            gameTime: gameTime,
            energyLevel: userProgress.currentLevel,
            dismiss: dismissView,
            showTimer: isTimeAttack
        )
    }
    
    private var crystalGridSection: some View {
        VStack(spacing: 15) {
            ForEach(0..<3) { row in
                HStack(spacing: 15) {
                    ForEach(0..<3) { column in
                        CrystalCell(
                            crystal: crystals[row][column],
                            isSelected: selectedCrystals.contains { $0.row == row && $0.column == column },
                            isPulsing: pulsingCrystals.contains("\(row)-\(column)"),
                            onTap: { selectCrystal(row: row, column: column) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(gridBackground)
    }
    
    private var gridBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color(hex: "570A57").opacity(0.5), radius: 15)
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 20) {
            hintButton
            fusionButton
            shuffleButton
        }
    }
    
    private var overlayElements: some View {
        ZStack {
            // Fusion particles
            ForEach(fusionParticles) { particle in
                Text(particle.emoji)
                    .font(.system(size: 30 * particle.scale))
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
            
            if showPowerUpAnimation {
                powerUpAnimationView
            }
            
            if showComboText {
                comboTextView
            }
            
            if showGameOver {
                GameOverView(
                    score: score,
                    highScore: userProgress.highScore,
                    level: userProgress.currentLevel,
                    onRestart: restartGame,
                    onDismiss: dismissView
                )
                .transition(.opacity)
            }
            
            if showTutorial {
                TutorialView1(onDismiss: { showTutorial = false })
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Setup and Timer
    
    private func setupGame() {
        loadUserProgress()
        initializeGame()
        
        if userProgress.currentLevel <= 1 && !isTimeAttack {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTutorial = true
            }
        }
    }
    
    private func updateGameTimer(_ time: Date) {
        if isTimeAttack && isGameActive && gameTime > 0 {
            gameTime -= 1
            if gameTime == 0 {
                endGame()
            }
        }
    }
    
    // Initialize a new game
    private func initializeGame() {
        score = 0
        fusionPower = 1
        comboMultiplier = 1
        gameTime = 60 + (userProgress.currentLevel * 5) // More time for higher levels
        isGameActive = true
        showGameOver = false
        
        // Initialize crystals
        for row in 0..<3 {
            for column in 0..<3 {
                crystals[row][column] = Crystal.random(level: userProgress.currentLevel)
            }
        }
    }
    
    // Restart the game
    private func restartGame() {
        withAnimation {
            initializeGame()
        }
    }
    
    // End the game
    private func endGame() {
        isGameActive = false
        
        // Update high score if needed
        if score > userProgress.highScore {
            var updatedProgress = userProgress
            updatedProgress.highScore = score
            
            // Check for level up
            let requiredPoints = calculateRequiredPoints(updatedProgress.currentLevel)
            if score >= requiredPoints {
                updatedProgress.currentLevel += 1
            }
            
            if let encoded = try? JSONEncoder().encode(updatedProgress) {
                userProgressData = encoded
            }
        }
        
        // Show game over screen
        withAnimation(.easeIn(duration: 0.5)) {
            showGameOver = true
        }
    }
    
    // Show a hint by pulsing matching crystals
    private func showHint() {
        // Clear previous hints
        pulsingCrystals.removeAll()
        
        // Check for potential matches
        for row in 0..<3 {
            for col in 0..<3 {
                // Check horizontal matches
                if col < 1 && crystals[row][col].type == crystals[row][col+1].type {
                    if col < 2 && crystals[row][col].type == crystals[row][col+2].type {
                        pulsingCrystals.insert("\(row)-\(col)")
                        pulsingCrystals.insert("\(row)-\(col+1)")
                        pulsingCrystals.insert("\(row)-\(col+2)")
                        break
                    }
                }
                
                // Check vertical matches
                if row < 1 && crystals[row][col].type == crystals[row+1][col].type {
                    if row < 2 && crystals[row][col].type == crystals[row+2][col].type {
                        pulsingCrystals.insert("\(row)-\(col)")
                        pulsingCrystals.insert("\(row+1)-\(col)")
                        pulsingCrystals.insert("\(row+2)-\(col)")
                        break
                    }
                }
                
                // Check diagonal matches
                if row < 1 && col < 1 &&
                   crystals[row][col].type == crystals[row+1][col+1].type &&
                   row < 2 && col < 2 &&
                   crystals[row][col].type == crystals[row+2][col+2].type {
                    pulsingCrystals.insert("\(row)-\(col)")
                    pulsingCrystals.insert("\(row+1)-\(col+1)")
                    pulsingCrystals.insert("\(row+2)-\(col+2)")
                    break
                }
                
                if row < 1 && col > 1 &&
                   crystals[row][col].type == crystals[row+1][col-1].type &&
                   row < 2 && col > 0 &&
                   crystals[row][col].type == crystals[row+2][col-2].type {
                    pulsingCrystals.insert("\(row)-\(col)")
                    pulsingCrystals.insert("\(row+1)-\(col-1)")
                    pulsingCrystals.insert("\(row+2)-\(col-2)")
                    break
                }
            }
            
            if !pulsingCrystals.isEmpty {
                break
            }
        }
        
        // If no matches found, show a message
        if pulsingCrystals.isEmpty {
            // Maybe shuffle the board to create matches
            shuffleCrystals()
        }
        
        // Clear the hint after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            pulsingCrystals.removeAll()
        }
    }
    
    // Shuffle the crystals
    private func shuffleCrystals() {
        withAnimation {
            isFusing = true
            
            // Create a new shuffled crystal board
            var newCrystals: [[Crystal]] = Array(repeating: Array(repeating: Crystal.random(level: userProgress.currentLevel), count: 3), count: 3)
            
            // Ensure there's at least one match
            var hasMatch = false
            
            while !hasMatch {
                // Check if we have at least one match
                for row in 0..<3 {
                    // Check rows
                    if newCrystals[row][0].type == newCrystals[row][1].type &&
                       newCrystals[row][1].type == newCrystals[row][2].type {
                        hasMatch = true
                        break
                    }
                    
                    // Check columns
                    for col in 0..<3 {
                        if row == 0 {
                            if newCrystals[0][col].type == newCrystals[1][col].type &&
                               newCrystals[1][col].type == newCrystals[2][col].type {
                                hasMatch = true
                                break
                            }
                        }
                    }
                    
                    if hasMatch {
                        break
                    }
                }
                
                // Check diagonals
                if !hasMatch {
                    if (newCrystals[0][0].type == newCrystals[1][1].type &&
                        newCrystals[1][1].type == newCrystals[2][2].type) ||
                       (newCrystals[0][2].type == newCrystals[1][1].type &&
                        newCrystals[1][1].type == newCrystals[2][0].type) {
                        hasMatch = true
                    }
                }
                
                if !hasMatch {
                    // Regenerate board
                    for row in 0..<3 {
                        for column in 0..<3 {
                            newCrystals[row][column] = Crystal.random(level: userProgress.currentLevel)
                        }
                    }
                }
            }
            
            // Update the board
            crystals = newCrystals
            
            // Reset selection
            selectedCrystals.removeAll()
        }
        
        // End fusion animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isFusing = false
        }
    }
    
    // Select a crystal for potential matching
    private func selectCrystal(row: Int, column: Int) {
        guard isGameActive && !isFusing else { return }
        
        // Toggle selection
        let key = "\(row)-\(column)"
        
        if let index = selectedCrystals.firstIndex(where: { $0.row == row && $0.column == column }) {
            selectedCrystals.remove(at: index)
        } else {
            // Add to selection
            selectedCrystals.append((row, column))
            
            // Play selection sound effect (would be implemented in actual app)
            
            // Check if we have enough selected crystals to check for match
            if selectedCrystals.count >= 3 {
                checkSelectedMatches()
            }
        }
    }
    
    // Check if selected crystals form a match
    private func checkSelectedMatches() {
        // Need at least 3 selections
        guard selectedCrystals.count >= 3 else { return }
        
        // Check if all selected crystals are of the same type
        let firstType = crystals[selectedCrystals[0].row][selectedCrystals[0].column].type
        let allSameType = selectedCrystals.allSatisfy {
            crystals[$0.row][$0.column].type == firstType
        }
        
        if allSameType {
            // Calculate the power of the fusion
            var totalPower = 0
            for coordinate in selectedCrystals {
                totalPower += crystals[coordinate.row][coordinate.column].power
            }
            
            // Score calculation
            let basePoints = 100 * totalPower
            let levelMultiplier = max(1, userProgress.currentLevel / 2)
            let fusionPoints = basePoints * fusionPower * levelMultiplier * comboMultiplier
            
            score += fusionPoints
            lastFusion = fusionPoints
            
            // Increment fusion power
            fusionPower += 1
            
            // Increment combo multiplier
            comboMultiplier += 1
            
            // Show animation
            showFusionSuccess()
            
            // Create fusion particles
            createFusionParticles()
            
            // Replace matched crystals
            replaceFusedCrystals()
        } else {
            // Reset combo if a mismatch occurs
            comboMultiplier = 1
        }
        
        // Clear selection in either case
        selectedCrystals.removeAll()
    }
    
    // Perform automated fusion (for traditional match-3 mechanics)
    private func performFusion() {
        guard !isFusing else { return }
        isFusing = true
        
        // Update crystals with new random crystals
        for row in 0..<3 {
            for column in 0..<3 {
                crystals[row][column] = getRandomCrystal()
            }
        }
        
        // Check for matches after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkFusions()
            self.isFusing = false
        }
        
        successfulMatches += 1
        if successfulMatches % 2 == 0 {
            showQuiz = true
        }
    }
    
    // Create fusion particle effects
    private func createFusionParticles() {
        guard !selectedCrystals.isEmpty else { return }
        
        // Clear existing particles
        fusionParticles.removeAll()
        
        // Calculate center position of selected crystals
        var centerX: CGFloat = 0
        var centerY: CGFloat = 0
        
        for coordinate in selectedCrystals {
            // This is an approximation - in a real app you'd use geometry reader
            centerX += CGFloat(100 + coordinate.column * 120)
            centerY += CGFloat(300 + coordinate.row * 120)
        }
        
        centerX /= CGFloat(selectedCrystals.count)
        centerY /= CGFloat(selectedCrystals.count)
        
        // Create particles
        for _ in 0..<20 {
            let particle = FusionParticle(
                position: CGPoint(x: centerX, y: centerY),
                scale: CGFloat.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                opacity: 1.0,
                emoji: fusionEffects.randomElement()!
            )
            fusionParticles.append(particle)
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 1.5)) {
            for i in 0..<fusionParticles.count {
                // Randomize end position
                let angle = Double.random(in: 0..<(2 * Double.pi))
                let distance = CGFloat.random(in: 50...200)
                let endX = centerX + distance * CGFloat(cos(angle))
                let endY = centerY + distance * CGFloat(sin(angle))
                
                fusionParticles[i].position = CGPoint(x: endX, y: endY)
                fusionParticles[i].opacity = 0
                fusionParticles[i].rotation += Double.random(in: 180...360)
            }
        }
        
        // Remove particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            fusionParticles.removeAll()
        }
    }
    
    // Replace fused crystals with new ones
    private func replaceFusedCrystals() {
        // Replace the crystals at the selected positions
        for coordinate in selectedCrystals {
            crystals[coordinate.row][coordinate.column] = Crystal.random(level: userProgress.currentLevel)
        }
    }
    
    // Show fusion success UI
    private func showFusionSuccess() {
        // Show power up animation
        withAnimation(.spring()) {
            showPowerUpAnimation = true
        }
        
        // Hide power up animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showPowerUpAnimation = false
            }
        }
        
        // Show combo text if combo > 1
        if comboMultiplier > 1 {
            withAnimation(.spring()) {
                showComboText = true
            }
            
            // Hide combo text after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showComboText = false
                }
            }
        }
        
        // Update progress
        updateProgress()
    }
    
    // Check for automatic fusions (traditional match-3)
    private func checkFusions() {
        var fusionCount = 0
        var matchedPositions: [(row: Int, column: Int)] = []
        
        // Check rows
        for row in 0..<3 {
            if crystals[row][0].type == crystals[row][1].type &&
               crystals[row][1].type == crystals[row][2].type {
                fusionCount += 1
                matchedPositions.append((row, 0))
                matchedPositions.append((row, 1))
                matchedPositions.append((row, 2))
            }
        }
        
        // Check columns
        for col in 0..<3 {
            if crystals[0][col].type == crystals[1][col].type &&
               crystals[1][col].type == crystals[2][col].type {
                fusionCount += 1
                matchedPositions.append((0, col))
                matchedPositions.append((1, col))
                matchedPositions.append((2, col))
            }
        }
        
        // Check diagonals
        if crystals[0][0].type == crystals[1][1].type &&
           crystals[1][1].type == crystals[2][2].type {
            fusionCount += 1
            matchedPositions.append((0, 0))
            matchedPositions.append((1, 1))
            matchedPositions.append((2, 2))
        }
        
        if crystals[0][2].type == crystals[1][1].type &&
           crystals[1][1].type == crystals[2][0].type {
            fusionCount += 1
            matchedPositions.append((0, 2))
            matchedPositions.append((1, 1))
            matchedPositions.append((2, 0))
        }
        
        // Process matches if there are any
        if fusionCount > 0 {
            // Calculate total power of matched crystals
            var totalPower = 0
            for position in matchedPositions {
                totalPower += crystals[position.row][position.column].power
            }
            
            // Score calculation
            let basePoints = 100 * totalPower
            let levelMultiplier = max(1, userProgress.currentLevel / 2)
            let fusionPoints = basePoints * fusionCount * fusionPower * comboMultiplier
            
            score += fusionPoints
            lastFusion = fusionPoints
            
            // Increment fusion power for consecutive matches
            fusionPower += 1
            
            // Increment combo
            comboMultiplier += 1
            
            // Show animation
            showFusionSuccess()
            
            // Replace matches with new crystals
            for position in matchedPositions {
                crystals[position.row][position.column] = Crystal.random(level: userProgress.currentLevel)
            }
        } else {
            // Reset fusion power and combo when no matches
            fusionPower = 1
            comboMultiplier = 1
        }
    }
    
    // Update game progress
    private func updateProgress() {
        var progress = userProgress
        progress.currentScore = score
        progress.highScore = max(progress.highScore, score)
        
        // Level up check
        let requiredPoints = calculateRequiredPoints(progress.currentLevel)
        if score >= requiredPoints && progress.currentScore < score {
            progress.currentLevel += 1
            
            // Maybe show a level up animation here
        }
        
        if let encoded = try? JSONEncoder().encode(progress) {
            userProgressData = encoded
        }
    }
    
    // Calculate points required for level up
    private func calculateRequiredPoints(_ level: Int) -> Int {
        return 1000 * level * level // Exponential scaling
    }
    
    // Load user progress from storage
    private func loadUserProgress() {
        if let decoded = try? JSONDecoder().decode(UserProgress.self, from: userProgressData) {
            userProgress = decoded
        }
    }
    
    // Update getRandomCrystal function
    private func getRandomCrystal() -> Crystal {
        let level = userProgress.currentLevel
        let random = Int.random(in: 1...100)
        
        let type = CrystalType.allCases.randomElement()!
        let rarity: CrystalRarity
        let emoji: String
        let power: Int
        
        if level >= 10 && random <= 10 {
            rarity = .epic
            emoji = epicCrystals.randomElement()!
            power = Crystal.getPower(rarity: .epic)
        } else if level >= 5 && random <= 30 {
            rarity = .rare
            emoji = rareCrystals.randomElement()!
            power = Crystal.getPower(rarity: .rare)
        } else {
            rarity = .common
            emoji = basicCrystals.randomElement()!
            power = Crystal.getPower(rarity: .common)
        }
        
        return Crystal(
            emoji: emoji,
            type: type,
            rarity: rarity,
            power: power,
            position: CGPoint(x: 0, y: 0)
        )
    }
    
    // MARK: - Button Components
    private var hintButton: some View {
        Button(action: showHint) {
            VStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                Text("HINT")
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(.yellow)
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Circle()
                            .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    private var fusionButton: some View {
        Button(action: performFusion) {
            HStack {
                Image(systemName: "atom")
                Text("FUSION")
                    .bold()
            }
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 200, height: 60)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF2E63"),
                                    Color(hex: "7E1DC3")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Energy Effect
                    ForEach(0..<8) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .scaleEffect(isFusing ? 0.5 : 1.5)
                            .opacity(isFusing ? 0 : 0.5)
                            .animation(
                                .easeOut(duration: 1)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.1),
                                value: isFusing
                            )
                    }
                }
            )
            .shadow(color: Color(hex: "FF2E63").opacity(0.5), radius: 10)
        }
        .disabled(isFusing)
        .scaleEffect(isFusing ? 0.95 : 1.0)
    }
    
    private var shuffleButton: some View {
        Button(action: shuffleCrystals) {
            VStack {
                Image(systemName: "shuffle")
                    .font(.system(size: 24))
                Text("SHUFFLE")
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(Color(hex: "00B4D8"))
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Circle()
                            .strokeBorder(Color(hex: "00B4D8").opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Animation Views
    private var powerUpAnimationView: some View {
        VStack(spacing: 10) {
            Text(fusionEffects.randomElement()!)
                .font(.system(size: 60))
            Text("FUSION x\(fusionPower)!")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            Text("+\(lastFusion) POINTS")
                .font(.headline)
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FF2E63").opacity(0.8))
                .shadow(color: Color(hex: "FF2E63"), radius: 20)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var comboTextView: some View {
        Text("COMBO x\(comboMultiplier)!")
            .font(.title2)
            .bold()
            .foregroundColor(.yellow)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.7))
            .cornerRadius(20)
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
            .offset(y: -180)
    }
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views

// Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "2E0249"),
                Color(hex: "570A57"),
                Color(hex: "A91079"),
                Color(hex: "0B0033")
            ]),
            startPoint: start,
            endPoint: end
        )
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                start = UnitPoint(x: CGFloat.random(in: 0...0.5), y: CGFloat.random(in: 0...0.5))
                end = UnitPoint(x: CGFloat.random(in: 0.5...1), y: CGFloat.random(in: 0.5...1))
            }
        }
    }
}

// Crystal Grid Background Pattern
struct CrystalGridBackgroundView: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<6) { row in
                HStack(spacing: 30) {
                    ForEach(0..<3) { col in
                        Image(systemName: "hexagon.fill")
                            .foregroundColor(.white.opacity(0.05))
                            .font(.system(size: 40))
                            .rotationEffect(.degrees(90))
                            .offset(x: CGFloat(row % 2 == 0 ? 15 : 0))
                    }
                }
            }
        }
        .rotationEffect(.degrees(30))
        .blur(radius: 3)
    }
}

// Game Header View
struct GameHeaderView: View {
    let score: Int
    let fusionPower: Int
    let gameTime: Int
    let energyLevel: Int
    let dismiss: () -> Void
    let showTimer: Bool
    
    var body: some View {
        HStack {
            // Back Button
            Button(action: dismiss) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            Spacer()
            
            // Only show timer if showTimer is true
            if showTimer {
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("\(gameTime)s")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
            
            // Energy Level
            HStack(spacing: 5) {
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.yellow)
                Text("LEVEL \(energyLevel)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                HStack(spacing: 2) {
                    Text("FUSION")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("x\(fusionPower)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

// Crystal Cell View
struct CrystalCell: View {
    let crystal: CrystalFusionView.Crystal
    let isSelected: Bool
    let isPulsing: Bool
    let onTap: () -> Void
    
    @State private var pulse = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Hexagon background
                Image(systemName: "hexagon.fill")
                    .foregroundColor(
                        isSelected ? Color(hex: "7E1DC3") : Color(hex: "570A57").opacity(0.8)
                    )
                    .font(.system(size: 80))
                    .shadow(
                        color: isSelected ? Color(hex: "FF2E63").opacity(0.5) : Color.clear,
                        radius: 10
                    )
                
                // Crystal emoji
                Text(crystal.emoji)
                    .font(.system(size: 40))
            }
            .scaleEffect(pulse ? 1.1 : 1.0)
            .animation(
                isPulsing ?
                    Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                    .default,
                value: pulse
            )
            .onChange(of: isPulsing) { newValue in
                pulse = newValue
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Game Over View
struct GameOverView: View {
    let score: Int
    let highScore: Int
    let level: Int
    let onRestart: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    Text("SCORE")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(score)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("HIGH SCORE: \(highScore)")
                        .font(.headline)
                        .foregroundColor(score >= highScore ? .yellow : .gray)
                    
                    if score >= highScore {
                        Text("NEW RECORD!")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.top, 5)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                
                VStack(spacing: 20) {
                    Button(action: onRestart) {
                        Text("PLAY AGAIN")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF2E63"), Color(hex: "7E1DC3")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                    }
                    
                    Button(action: onDismiss) {
                        Text("MAIN MENU")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(25)
                    }
                }
            }
            .padding(30)
        }
    }
}

// Tutorial View
struct TutorialView1: View {
    let onDismiss: () -> Void
    @State private var currentPage = 0
    
    let pages = [
        (title: "Welcome to Crystal Fusion!",
         content: "Match crystals of the same type to create powerful fusions and increase your score.",
         image: "diamond.fill"),
        
        (title: "Select Crystals",
         content: "Tap on three or more crystals of the same type to fuse them and earn points.",
         image: "hand.tap.fill"),
        
        (title: "Build Combos",
         content: "Chain multiple matches together to increase your combo multiplier and score big!",
         image: "chart.line.uptrend.xyaxis"),
        
        (title: "Watch the Timer",
         content: "Complete as many fusions as possible before time runs out.",
         image: "clock.fill")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text(pages[currentPage].title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Image(systemName: pages[currentPage].image)
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "FF2E63"))
                    .padding(30)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: "FF2E63").opacity(0.3), lineWidth: 2)
                            )
                    )
                
                Text(pages[currentPage].content)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { page in
                        Circle()
                            .fill(currentPage == page ? Color(hex: "FF2E63") : Color.gray)
                            .frame(width: 10, height: 10)
                    }
                }
                
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "FF2E63"))
                            .cornerRadius(20)
                        }
                    } else {
                        Button(action: onDismiss) {
                            Text("Let's Play!")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color(hex: "FF2E63"))
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(30)
        }
    }
}

// MARK: - Helper Extensions

// Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


