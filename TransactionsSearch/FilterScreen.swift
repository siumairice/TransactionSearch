import SwiftUI

struct FilterScreen: View {
    @ObservedObject var viewModel: FilterViewModel
    var onApply: ([Transaction]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    DatePickerField(title: "Start Date", value: $viewModel.startDate)
                    DatePickerField(title: "End Date", value: $viewModel.endDate)
                }
                
                HStack(spacing: 20) {
                    AmountField(title: "Min. Amount", placeholder: "No Minimum", text: $viewModel.minAmount)
                    AmountField(title: "Max. Amount", placeholder: "No Maximum", text: $viewModel.maxAmount)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Transaction Type")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Menu {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Button(type.rawValue) { viewModel.selectedTransactionType = type }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedTransactionType.rawValue)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                HStack {
                    Text("Cheques Only")
                        .font(.system(size: 16))
                    Spacer()
                    Toggle("", isOn: $viewModel.chequesOnly)
                        .labelsHidden()
                }
                .padding(.top, 5)
                
                // Search Settings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Settings")
                        .font(.headline)
                    
                    Toggle("Enable Semantic Search", isOn: $viewModel.isSemanticSearchEnabled)
                        .font(.system(size: 16))
                }
                .padding(.vertical, 10)
            }
            .padding()
            
            Button(action: {
                viewModel.applyFilters()
                onApply(viewModel.filteredTransactions)
                dismiss()
            }) {
                Text("Apply")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            Spacer()
        }
        .navigationTitle("Filter by")
        .navigationBarItems(trailing: Button("Clear") {
            viewModel.resetFilters()
        }
        .foregroundColor(.blue))
        .background(Color(.systemBackground))
    }
}

// Keep the existing helper components
struct DatePickerField: View {
    var title: String
    @Binding var value: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            DatePicker("", selection: $value, displayedComponents: .date)
                .labelsHidden()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AmountField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}
