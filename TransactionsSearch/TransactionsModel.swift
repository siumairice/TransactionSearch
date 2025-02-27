import Foundation
import NaturalLanguage

// Transaction Type Enum for clarity
enum TransactionType: String, CaseIterable {
    case all = "All Types"
    case deposit = "Deposits"
    case withdrawal = "Withdrawals"
    case transfer = "Transfers"
}

// Transaction Model
struct Transaction: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let type: TransactionType
    let amount: Double
    let isCheque: Bool
    var embeddingVector: [Float]?
    
    // New: Categories associated with this transaction
    var category: [String]

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func formattedDate() -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, yyyy"
        return displayFormatter.string(from: date)
    }

    mutating func computeEmbedding() {
        self.embeddingVector = TransactionEmbeddingManager.shared.generateEmbedding(for: title)
    }
}


extension Transaction {
    static var sampleTransactions: [Transaction] {
        var transactions = [
            Transaction(date: Transaction.dateFormatter.date(from: "2025-02-20")!,
                        title: "Amazon Purchase",
                        type: .withdrawal,
                        amount: -50.00,
                        isCheque: false,
                        category: ["Shopping", "Online"]),

            Transaction(date: Transaction.dateFormatter.date(from: "2025-02-20")!,
                        title: "Salary Deposit",
                        type: .deposit,
                        amount: 3000.00,
                        isCheque: false,
                        category: ["Income"]),

            Transaction(date: Transaction.dateFormatter.date(from: "2025-02-06")!,
                        title: "Starbucks Coffee",
                        type: .withdrawal,
                        amount: -4.50,
                        isCheque: false,
                        category: ["Food & Drink", "Coffee"]),

            Transaction(date: Transaction.dateFormatter.date(from: "2025-01-30")!,
                        title: "Gym Membership Fee",
                        type: .withdrawal,
                        amount: -50.00,
                        isCheque: false,
                        category: ["Health", "Subscription"])
        ]

        return transactions.map { var transaction = $0; transaction.computeEmbedding(); return transaction }
    }
}


// This class handles the word embedding operations
class TransactionEmbeddingManager {
    static let shared = TransactionEmbeddingManager()
    
    private var wordEmbedding: NLEmbedding?
    
    private init() {
        // Load the word embedding model
        wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }
    
    
    func generateEmbedding(for text: String) -> [Float]? {
        guard let wordEmbedding = wordEmbedding else { return nil }
        
        // Clean the text
        let cleanedText = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Tokenize the text
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = cleanedText
        
        var tokens = [String]()
        tokenizer.enumerateTokens(in: cleanedText.startIndex..<cleanedText.endIndex) { range, _ in
            let token = String(cleanedText[range])
            tokens.append(token)
            return true
        }
        
        print(tokens)
        
        // Generate embeddings for each token and average them
        var sumVector = Array(repeating: Float(0), count: 300) // Typical size for word embeddings
        var count = 0
        
        for token in tokens {
            if let vector = wordEmbedding.vector(for: token) {
                for i in 0..<min(vector.count, sumVector.count) {
                    sumVector[i] += Float(vector[i])
                }
                count += 1
            }
        }
        
        // Average the vectors
        if count > 0 {
            for i in 0..<sumVector.count {
                sumVector[i] /= Float(count)
            }
        
            return sumVector
        } else {
            return nil
        }
    }
    
    // Calculate cosine similarity between two embedding vectors
    func cosineSimilarity(between vector1: [Float], and vector2: [Float]) -> Float {
        guard vector1.count == vector2.count && vector1.count > 0 else { return 0 }
        
        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            magnitude1 += vector1[i] * vector1[i]
            magnitude2 += vector2[i] * vector2[i]
        }
        
        magnitude1 = sqrt(magnitude1)
        magnitude2 = sqrt(magnitude2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
}
