import SwiftUI

struct TransactionListScreen: View {
    @StateObject private var viewModel = FilterViewModel()
    @State private var searchText: String = ""
    @State private var showFilterScreen = false
    @State private var showSearchSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .foregroundColor(.primary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: searchText) { newValue in
                                viewModel.searchText = newValue
                                viewModel.applyFilters()
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                viewModel.searchText = ""
                                viewModel.applyFilters()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Toggle for Semantic Search
                        Button(action: { showSearchSettings = true }) {
                            Image(systemName: viewModel.isSemanticSearchEnabled ? "brain" : "textformat")
                                .foregroundColor(.blue)
                        }
                        .actionSheet(isPresented: $showSearchSettings) {
                            ActionSheet(
                                title: Text("Search Type"),
                                message: Text("Choose how to search transactions"),
                                buttons: [
                                    .default(Text("Semantic Search")) {
                                        viewModel.isSemanticSearchEnabled = true
                                        if !searchText.isEmpty {
                                            viewModel.applyFilters()
                                        }
                                    },
                                    .default(Text("Text Search")) {
                                        viewModel.isSemanticSearchEnabled = false
                                        if !searchText.isEmpty {
                                            viewModel.applyFilters()
                                        }
                                    },
                                    .cancel()
                                ]
                            )
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)

                    // Button for opening filter screen (if needed)
                    Button(action: { showFilterScreen = true }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Filter")
                                .font(.system(size: 16))
                        }
                        .padding(10)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color(.systemGray6))

                // Category Tags - Moved under Search Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(["Shopping", "Food & Drink", "Income", "Health", "Subscription", "Bills", "Entertainment", "Transportation"], id: \.self) { category in
                            Button(action: {
                                if viewModel.selectedCategories.contains(category) {
                                    viewModel.selectedCategories.removeAll { $0 == category }
                                } else {
                                    viewModel.selectedCategories.append(category)
                                }
                                viewModel.applyFilters()
                            }) {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.selectedCategories.contains(category) ? Color.blue.opacity(0.3) : Color(.systemGray5))
                                    .cornerRadius(12)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 4)
                .background(Color(.systemGray6))

                if !searchText.isEmpty && viewModel.isSemanticSearchEnabled {
                    HStack {
                        Text("Semantic search active")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    .background(Color(.systemGray6))
                }

                // Transaction List
                List {
                    ForEach(groupTransactionsByDate(), id: \.key) { date, transactions in
                        Section(header: DateHeader(title: date)) {
                            ForEach(transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.white)
            }
            .background(Color(.systemGray6))
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Test Data") {
                        viewModel.addTestTransactions()
                    }
                }
            }
            .sheet(isPresented: $showFilterScreen) {
                NavigationStack {
                    FilterScreen(viewModel: viewModel) { filteredResults in
                        viewModel.filteredTransactions = filteredResults
                    }
                }
            }
        }
    }

    private func groupTransactionsByDate() -> [(key: String, value: [Transaction])] {
        let transactions = viewModel.filteredTransactions
        let grouped = Dictionary(grouping: transactions, by: { $0.formattedDate() })
        return grouped.sorted { $0.key > $1.key }
    }
}


// Section Header Styling
struct DateHeader: View {
    var title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .padding(.top, 8)
    }
}

// Transaction Row
struct TransactionRow: View {
    var transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(transaction.title)
                .font(.headline)
            
            if transaction.isCheque {
                Text("Cheque")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Display categories as tags
            HStack {
                ForEach(transaction.category, id: \.self) { category in
                    Text(category)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .font(.caption)
                }
            }
            
            Text(String(format: "%.2f", transaction.amount))
                .font(.subheadline)
                .foregroundColor(transaction.amount < 0 ? .red : .green)
        }
        .padding(.vertical, 6)
    }
}


#Preview {
    TransactionListScreen()
}
