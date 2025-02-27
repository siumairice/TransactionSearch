//
//  TransactionEmbeddingManager.swift
//  TransactionsSearch
//
//  Created by Nicole Go on 2025-02-27.
//

import NaturalLanguage

class TransactionEmbeddingManager {
    static let shared = TransactionEmbeddingManager()
    
    private var sentenceEmbedding: NLEmbedding?
    
    private init() {
        // Load the sentence embedding model
        sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    func generateEmbedding(for text: String) -> [Float]? {
        guard let sentenceEmbedding = sentenceEmbedding else { return nil }
        
        // Clean the text
        let cleanedText = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get sentence embedding directly
        // Note: NLEmbedding.vector(for:) returns [Double], so we convert to [Float]
        if let vector = sentenceEmbedding.vector(for: cleanedText) {
            return vector.map { Float($0) }
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
    
    // Find similar transactions based on embedding similarity
    func findSimilarTransactions(query: String, transactions: [String], threshold: Float = 0.7) -> [String] {
        guard let queryEmbedding = generateEmbedding(for: query) else { return [] }
        
        var similarTransactions = [String]()
        
        for transaction in transactions {
            if let transactionEmbedding = generateEmbedding(for: transaction) {
                let similarity = cosineSimilarity(between: queryEmbedding, and: transactionEmbedding)
                if similarity >= threshold {
                    similarTransactions.append(transaction)
                }
            }
        }
        
        return similarTransactions
    }
}



//
//// This class handles the word embedding operations
//class TransactionEmbeddingManager {
//    static let shared = TransactionEmbeddingManager()
//
//    private var wordEmbedding: NLEmbedding?
//
//    private init() {
//        // Load the word embedding model
//        wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
//    }
//
//
//    func generateEmbedding(for text: String) -> [Float]? {
//        guard let wordEmbedding = wordEmbedding else { return nil }
//
//        // Clean the text
//        let cleanedText = text.lowercased()
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//
//        // Tokenize the text
//        let tokenizer = NLTokenizer(unit: .word)
//        tokenizer.string = cleanedText
//
//        var tokens = [String]()
//        tokenizer.enumerateTokens(in: cleanedText.startIndex..<cleanedText.endIndex) { range, _ in
//            let token = String(cleanedText[range])
//            tokens.append(token)
//            return true
//        }
//
//        print(tokens)
//
//        // Generate embeddings for each token and average them
//        var sumVector = Array(repeating: Float(0), count: 300) // Typical size for word embeddings
//        var count = 0
//
//        for token in tokens {
//            if let vector = wordEmbedding.vector(for: token) {
//                for i in 0..<min(vector.count, sumVector.count) {
//                    sumVector[i] += Float(vector[i])
//                }
//                count += 1
//            }
//        }
//
//        // Average the vectors
//        if count > 0 {
//            for i in 0..<sumVector.count {
//                sumVector[i] /= Float(count)
//            }
//
//            return sumVector
//        } else {
//            return nil
//        }
//    }
//
//    // Calculate cosine similarity between two embedding vectors
//    func cosineSimilarity(between vector1: [Float], and vector2: [Float]) -> Float {
//        guard vector1.count == vector2.count && vector1.count > 0 else { return 0 }
//
//        var dotProduct: Float = 0
//        var magnitude1: Float = 0
//        var magnitude2: Float = 0
//
//        for i in 0..<vector1.count {
//            dotProduct += vector1[i] * vector2[i]
//            magnitude1 += vector1[i] * vector1[i]
//            magnitude2 += vector2[i] * vector2[i]
//        }
//
//        magnitude1 = sqrt(magnitude1)
//        magnitude2 = sqrt(magnitude2)
//
//        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
//
//        return dotProduct / (magnitude1 * magnitude2)
//    }
//}
