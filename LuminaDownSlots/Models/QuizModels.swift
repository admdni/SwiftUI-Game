import Foundation

struct QuizQuestion: Codable {
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    var allAnswers: [String] {
        (incorrectAnswers + [correctAnswer]).shuffled()
    }
}

// TMDB API için model
struct MovieQuestion: Codable {
    let results: [Movie]
}

struct Movie: Codable {
    let title: String
    let overview: String
    let releaseDate: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case overview
        case releaseDate = "release_date"
    }
} 