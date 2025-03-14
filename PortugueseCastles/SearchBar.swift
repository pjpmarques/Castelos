import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search castles", text: $searchText)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(minHeight: 36)
                    .onTapGesture {
                        withAnimation {
                            isSearching = true
                        }
                    }
                
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
                withAnimation {
                    isSearching = true
                }
            }
            
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
            // This allows us to detect when the search field is focused
            NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    isSearching = true
                }
            }
        }
    }
} 