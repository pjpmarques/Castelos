//
// SearchResultsView.swift
//
// This view displays search results for castles in an alphabetically sorted list.
// It handles displaying filtered castle search results based on user input, showing all castles 
// alphabetically when no search text is entered, indicating visited castles with checkmarks,
// and managing the selection of castles from the results list with appropriate transitions
// back to the map view.
//

import SwiftUI

struct SearchResultsView: View {
    // Reference to the data service that provides access to castle information
    @ObservedObject var dataService: CastleDataService
    
    // Bindings to parent view state
    @Binding var searchText: String       // The current search query text
    @Binding var selectedCastle: Castle?  // The currently selected castle (if any)
    @Binding var isSearching: Bool        // Whether search mode is active
    
    // Filtered castles based on search text - returns all castles alphabetically when search text is empty
    var filteredCastles: [Castle] {
        // Always show some castles, even with empty text
        return dataService.searchCastles(query: searchText)
    }
    
    var body: some View {
        List {
            // Handle empty search results
            if filteredCastles.isEmpty {
                Text("No castles found matching '\(searchText)'")
                    .foregroundColor(.secondary)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                // Castle results as selectable list items
                ForEach(filteredCastles) { castle in
                    Button(action: {
                        // First clear the search and dismiss keyboard
                        searchText = ""
                        
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        // Then set the selected castle with a slight delay to ensure UI updates properly
                        // This helps prevent UI glitches during the transition from search to map view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCastle = castle
                            // Removed animation for instant disappearance of search results
                            isSearching = false
                        }
                    }) {
                        HStack {
                            // Castle name
                            Text(castle.name)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Visual indicator for visited castles
                            if castle.isVisited {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle()) // Ensure the entire row is tappable
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // Prevent button layout issues in List
                }
            }
        }
        .listStyle(PlainListStyle()) // Clean, minimal list appearance without separators
    }
} 