import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var dataService: CastleDataService
    @Binding var searchText: String
    @Binding var selectedCastle: Castle?
    @Binding var isSearching: Bool
    
    var filteredCastles: [Castle] {
        // Always show some castles, even with empty text
        return dataService.searchCastles(query: searchText)
    }
    
    var body: some View {
        List {
            if filteredCastles.isEmpty {
                Text("No castles found matching '\(searchText)'")
                    .foregroundColor(.secondary)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                // Header for results
                if searchText.isEmpty {
                    Text("Castles starting with 'A'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                } else {
                    Text("Search results for '\(searchText)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                }
                
                // Castle results
                ForEach(filteredCastles) { castle in
                    Button(action: {
                        // First clear the search and dismiss keyboard
                        searchText = ""
                        
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        // Then set the selected castle with a slight delay to ensure UI updates properly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCastle = castle
                            withAnimation {
                                isSearching = false
                            }
                        }
                    }) {
                        HStack {
                            Text(castle.name)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if castle.isVisited {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle()) // Ensure the entire row is tappable
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // Prevent button layout issues
                }
            }
        }
        .listStyle(PlainListStyle())
    }
} 