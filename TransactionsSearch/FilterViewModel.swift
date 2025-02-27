import Foundation
import Combine

class FilterViewModel: ObservableObject {
    @Published var startDate: Date = Calendar.current.date(byAddingDays: -30, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var minAmount: String = ""
    @Published var maxAmount: String = ""
    @Published var selectedTransactionType: TransactionType = .all
    @Published var chequesOnly: Bool = false
    @Published var searchText: String = ""
    @Published var isSemanticSearchEnabled: Bool = true

    @Published var filteredTransactions: [Transaction] = []
    @Published var semanticResults: [Transaction] = []
    
    @Published var selectedCategories: [String] = []

    
    private var allTransactions: [Transaction]
    private var cancellables = Set<AnyCancellable>()
    
    init(transactions: [Transaction] = Transaction.sampleTransactions) {
        self.allTransactions = transactions
        self.filteredTransactions = transactions
        
        // Setup debounced search for semantic search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchTerm in
                guard let self = self, !searchTerm.isEmpty, self.isSemanticSearchEnabled else {
                    self?.semanticResults = []
                    return
                }
                self.performSemanticSearch(query: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    // Apply basic filters (date, amount, type, cheque)
    func applyFilters() {
        let minAmountValue = minAmount.isEmpty ? -Double.greatestFiniteMagnitude : Double(minAmount) ?? -Double.greatestFiniteMagnitude
        let maxAmountValue = maxAmount.isEmpty ? Double.greatestFiniteMagnitude : Double(maxAmount) ?? Double.greatestFiniteMagnitude
        

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        filteredTransactions = allTransactions.filter { transaction in
            let transactionDate = calendar.startOfDay(for: transaction.date)
            let matchesCategory = selectedCategories.isEmpty ||
                                  !transaction.category.filter { selectedCategories.contains($0) }.isEmpty
            let isWithinDateRange = transactionDate >= startOfDay && transactionDate <= endOfDay
            let isWithinAmountRange = transaction.amount >= minAmountValue && transaction.amount <= maxAmountValue
            let matchesTransactionType = selectedTransactionType == .all || transaction.type == selectedTransactionType
            let matchesChequeFilter = !chequesOnly || transaction.isCheque

            return isWithinDateRange && isWithinAmountRange && matchesTransactionType && matchesChequeFilter && matchesCategory

        }
        
        // If we have an active search term, apply it to the filtered results
        if !searchText.isEmpty {
            if isSemanticSearchEnabled {
                performSemanticSearch(query: searchText)
            } else {
                // Regular text search
                filteredTransactions = filteredTransactions.filter {
                    $0.title.lowercased().contains(searchText.lowercased()) ||
                    String(format: "%.2f", $0.amount).contains(searchText)
                }
            }
        }
    }
    
    // Perform semantic search on the currently filtered transactions
    func performSemanticSearch(query: String) {
        guard let queryEmbedding = TransactionEmbeddingManager.shared.generateEmbedding(for: query) else {
            semanticResults = []
            return
        }
        
        // Calculate similarity for each filtered transaction
        let similarityThreshold: Float = 0.3 // Adjust as needed
        
        let transactionsWithSimilarity = filteredTransactions.compactMap { transaction -> (Transaction, Float)? in
            guard let embedding = transaction.embeddingVector else { return nil }
            
            let similarity = TransactionEmbeddingManager.shared.cosineSimilarity(
                between: queryEmbedding,
                and: embedding
            )
            
            return (transaction, similarity)
        }
        .filter { $0.1 >= similarityThreshold }
        .sorted { $0.1 > $1.1 }
        
        semanticResults = transactionsWithSimilarity.map { $0.0 }
        
        // If semantic search is enabled and we have results, update filteredTransactions
        if isSemanticSearchEnabled && !semanticResults.isEmpty {
            filteredTransactions = semanticResults
        }
    }
    
    func resetFilters() {
        startDate = Calendar.current.date(byAddingDays: -30, to: Date()) ?? Date()
        endDate = Date()
        minAmount = ""
        maxAmount = ""
        selectedTransactionType = .all
        chequesOnly = false
        searchText = ""
        filteredTransactions = allTransactions
        semanticResults = []
    }
    
    // Helper to add days to date (for default date ranges)
    func addTestTransactions() {
        // Add more diverse transactions for testing semantic search
        let additionalTransactions = [
            Transaction(date: Date(),
                        title: "Grocery shopping at Safeway",
                        type: .withdrawal,
                        amount: -84.72,
                        isCheque: false,
                        category: ["Groceries", "Shopping"]),

            Transaction(date: Date(),
                        title: "Monthly rent payment",
                        type: .withdrawal,
                        amount: -1200.00,
                        isCheque: false,
                        category: ["Housing", "Bills"]),

            Transaction(date: Date(),
                        title: "Salary deposit",
                        type: .deposit,
                        amount: 2800.00,
                        isCheque: false,
                        category: ["Income", "Salary"]),

            Transaction(date: Date(),
                        title: "Coffee shop purchase",
                        type: .withdrawal,
                        amount: -4.50,
                        isCheque: false,
                        category: ["Food & Drink", "Coffee"]),

            Transaction(date: Date(),
                        title: "Restaurant dinner with friends",
                        type: .withdrawal,
                        amount: -82.35,
                        isCheque: false,
                        category: ["Food & Drink", "Dining Out"]),

            Transaction(date: Date(),
                        title: "Gas station fill up",
                        type: .withdrawal,
                        amount: -48.75,
                        isCheque: false,
                        category: ["Transportation", "Gas"]),

            Transaction(date: Date(),
                        title: "Phone bill payment",
                        type: .withdrawal,
                        amount: -85.00,
                        isCheque: false,
                        category: ["Bills", "Utilities"]),

            Transaction(date: Date(),
                        title: "Amazon purchase",
                        type: .withdrawal,
                        amount: -37.99,
                        isCheque: false,
                        category: ["Shopping", "Online"]),

            Transaction(date: Date(),
                        title: "Movie theater tickets",
                        type: .withdrawal,
                        amount: -24.50,
                        isCheque: false,
                        category: ["Entertainment", "Leisure"]),

            Transaction(date: Date(),
                        title: "Gym membership fee",
                        type: .withdrawal,
                        amount: -50.00,
                        isCheque: false,
                        category: ["Health", "Subscription"])
        ]

        // Compute embeddings for all new transactions
        var transactions = additionalTransactions.map { var transaction = $0; transaction.computeEmbedding(); return transaction }

        allTransactions.append(contentsOf: transactions)
        filteredTransactions = allTransactions
    }
}

extension Calendar {
    func date(byAddingDays days: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: days, to: date)
    }
}
