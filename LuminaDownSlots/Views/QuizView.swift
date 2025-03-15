import SwiftUI

struct QuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var question: QuizQuestion?
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var isLoading = true
    @State private var scale = 1.0
    @State private var rotationDegrees = 0.0
    
    var onComplete: (Bool) -> Void
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            // Quiz Content
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismissView() }) {
                        BackButton()
                    }
                    
                    Spacer()
                    
                    Text("QUIZ TIME!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                
                if isLoading {
                    Spacer()
                    LoadingView()
                    Spacer()
                } else if let question = question {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Question Card
                            QuestionCard(question: question.question)
                                .rotation3DEffect(.degrees(rotationDegrees), axis: (x: 0, y: 1, z: 0))
                                .scaleEffect(scale)
                                .onAppear {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        scale = 1
                                        rotationDegrees = 360
                                    }
                                }
                            
                            // Answer Options
                            VStack(spacing: 15) {
                                ForEach(question.allAnswers, id: \.self) { answer in
                                    AnswerButton(
                                        answer: answer,
                                        isSelected: selectedAnswer == answer,
                                        isCorrect: showResult ? answer == question.correctAnswer : nil,
                                        action: {
                                            if !showResult {
                                                withAnimation(.spring()) {
                                                    selectedAnswer = answer
                                                    isCorrect = answer == question.correctAnswer
                                                    showResult = true
                                                }
                                                
                                                // Haptic feedback
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    withAnimation {
                                                        showResult = false
                                                        onComplete(isCorrect)
                                                        dismissView()
                                                    }
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            // Result Modal
            if showResult {
                ZStack {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    ResultModal(
                        isCorrect: isCorrect,
                        correctAnswer: question?.correctAnswer ?? "",
                        points: isCorrect ? 1000 : 0
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            scale = 0.5
            rotationDegrees = 0
            loadQuestion()
        }
    }
    
    private func loadQuestion() {
        Task {
            do {
                let fetchedQuestion = try await QuizService.shared.fetchQuestion()
                DispatchQueue.main.async {
                    self.question = fetchedQuestion
                    self.isLoading = false
                }
            } catch {
                print("Error fetching question: \(error)")
                DispatchQueue.main.async {
                    dismissView()
                }
            }
        }
    }
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views
struct QuestionCard: View {
    let question: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FF2E63"))
            
            Text(question)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(hex: "FF2E63"), Color(hex: "7E1DC3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color(hex: "FF2E63").opacity(0.3), radius: 10)
    }
}

struct AnswerButton: View {
    let answer: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(answer)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.title3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return isSelected ? Color(hex: "FF2E63").opacity(0.2) : Color.black.opacity(0.3)
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green.opacity(0.5) : .red.opacity(0.5)
        }
        return isSelected ? Color(hex: "FF2E63").opacity(0.5) : Color.white.opacity(0.1)
    }
}

struct LoadingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FF2E63"))
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Loading Question...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Result Modal
struct ResultModal: View {
    let isCorrect: Bool
    let correctAnswer: String
    let points: Int
    
    var body: some View {
        VStack(spacing: 25) {
            // Result Icon
            ZStack {
                Circle()
                    .fill(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            // Result Text
            VStack(spacing: 10) {
                Text(isCorrect ? "Correct!" : "Wrong!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                if !isCorrect {
                    Text("Correct answer was:")
                        .foregroundColor(.gray)
                    
                    Text(correctAnswer)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                }
                
                if isCorrect {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(points)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.yellow)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isCorrect ? Color.green : Color.red,
                                    Color(hex: "7E1DC3")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: (isCorrect ? Color.green : Color.red).opacity(0.3),
            radius: 20
        )
    }
}

// iOS 14 Compatible Task Implementation
extension View {
    func task(priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View {
        self.onAppear {
            Task(priority: priority) {
                await action()
            }
        }
    }
}

#Preview {
    QuizView { _ in }
} 