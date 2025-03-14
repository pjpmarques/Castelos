/**
 * SearchBar.swift
 * 
 * Custom search bar for finding castles.
 * Handles user input, search state, and keyboard interactions.
 */
import SwiftUI

/**
 * SearchBar - Custom search input field with cancel button
 *
 * This view:
 * - Provides a search field for entering castle name queries
 * - Shows/hides a cancel button based on search state
 * - Manages the search input and search active state
 * - Handles keyboard interactions
 */
struct SearchBar: View {
    // Bindings to parent view
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            // MARK: - Search Input Field
            HStack {
                // Magnifying glass icon
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                // Text input field
                TextField("Search castles", text: $searchText)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(minHeight: 36)
                    .onTapGesture {
                        isSearching = true
                    }
                
                // Clear button - only shown when there's text
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .onTapGesture {
                isSearching = true
            }
            
            // MARK: - Cancel Button
            
            // Only show cancel button when actively searching
            if isSearching {
                Button(action: {
                    searchText = ""
                    withAnimation {
                        isSearching = false
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .onAppear {
            // MARK: - Keyboard Focus Detection
            
            // This allows us to detect when the search field is focused
            NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: .main) { _ in
                isSearching = true
            }
        }
    }
} 