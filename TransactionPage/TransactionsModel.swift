import Foundation

enum TransactionType: String, CaseIterable {
    case all = "All Types"
    case deposit = "Deposits"
    case withdrawal = "Withdrawals"
    case transfer = "Transfers"
}

struct Transaction: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let type: TransactionType
    let amount: Double
    let isCheque: Bool
    var embeddingVector: [Float]?
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


