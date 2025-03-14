import SwiftUI

struct VisitedCastlesView: View {
    @ObservedObject var dataService: CastleDataService
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCastle: Castle?
    
    var body: some View {
        NavigationView {
            List {
                if dataService.visitedCastles.isEmpty {
                    Text("You haven't visited any castles yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(dataService.visitedCastles) { castle in
                        Button(action: {
                            selectedCastle = castle
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "castle.turret.fill")
                                    .foregroundColor(.green)
                                
                                Text(castle.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Visited Castles")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 