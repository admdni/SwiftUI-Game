import Foundation

class QuizService {
    static let shared = QuizService()
    
    func fetchQuestion() async throws -> QuizQuestion {
        let url = URL(string: "api url")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TriviaResponse.self, from: data)
        
        guard let result = response.results.first else {
            throw URLError(.badServerResponse)
        }
        
        return QuizQuestion(
            question: result.question.removingPercentEncoding ?? result.question,
            correctAnswer: result.correct_answer.removingPercentEncoding ?? result.correct_answer,
            incorrectAnswers: result.incorrect_answers.map { $0.removingPercentEncoding ?? $0 }
        )
    }
}

// OpenTDB API Response Models
struct TriviaResponse: Codable {
    let response_code: Int
    let results: [TriviaResult]
}

struct TriviaResult: Codable {
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
} 
