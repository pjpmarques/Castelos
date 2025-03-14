//
// VisitedCastlesView.swift
//
// This view displays a list of castles that the user has marked as visited.
// It allows users to review their visited castles and select one to view on the map.
// The view is presented modally from the main ContentView and provides a way to
// track the user's progress in visiting different castles throughout Portugal.
//

import SwiftUI

struct VisitedCastlesView: View {
    // Reference to the data service that provides access to castle information
    @ObservedObject var dataService: CastleDataService
    
    // Environment value to dismiss this view when needed
    @Environment(\.presentationMode) var presentationMode
    
    // Binding to the selected castle in the parent view
    @Binding var selectedCastle: Castle?
    
    // Computed property to calculate the visit percentage
    private var visitPercentage: Double {
        let totalCount = dataService.castles.count
        let visitedCount = dataService.visitedCastles.count
        
        guard totalCount > 0 else { return 0 }
        return Double(visitedCount) / Double(totalCount) * 100
    }
    
    var body: some View {
        NavigationView {
            List {
                // Statistics section at the top
                Section(header: Text("Statistics")) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                        
                        Text("\(dataService.visitedCastles.count) castles out of \(dataService.castles.count) (\(String(format: "%.1f", visitPercentage))%)")
                            .font(.headline)
                    }
                    .padding(.vertical, 8)
                }
                
                // Castle listings section
                Section(header: Text("Your Visited Castles")) {
                    // Display a message when no castles have been visited
                    if dataService.visitedCastles.isEmpty {
                        Text("You haven't visited any castles yet.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        // Display list of visited castles
                        ForEach(dataService.visitedCastles) { castle in
                            Button(action: {
                                // Set the selected castle to navigate to it on the map
                                selectedCastle = castle
                                
                                // Dismiss this view after a short delay to allow for smooth transition
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack {
                                    // Castle icon
                                    Image(systemName: "building.columns.fill")
                                        .foregroundColor(.green)
                                    
                                    // Castle name
                                    Text(castle.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Visited indicator
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Modern iOS list style with grouped sections
            .navigationTitle("Visited Castles") // Title at the top of the view
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss button to close the view without selecting a castle
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 