import Foundation

struct UserProgress: Codable {
    var currentLevel: Int
    var highScore: Int
    var currentScore: Int
    var gamesPlayed: Int
    var maxCombo: Int
    var quizAnswered: Int
    var correctAnswers: Int
    
    static var empty: UserProgress {
        UserProgress(
            currentLevel: 1,
            highScore: 0,
            currentScore: 0,
            gamesPlayed: 0,
            maxCombo: 0,
            quizAnswered: 0,
            correctAnswers: 0
        )
    }
} 