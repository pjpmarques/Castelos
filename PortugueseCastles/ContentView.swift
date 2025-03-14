import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var dataService = CastleDataService()
    @State private var selectedCastle: Castle?
    @State private var showInfoSheet = false
    @State private var showVisitedCastles = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var mapType: MKMapType = .standard
    @State private var shouldResetMapView = false
    @State private var showFallbackSafari = false
    @State private var webViewErrorOccurred = false
    
    // Portugal's bounding box coordinates for resetting the map
    private let portugalRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.5, longitude: -8.0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map View
            MapView(dataService: dataService, 
                   selectedCastle: $selectedCastle, 
                   showInfoSheet: $showInfoSheet,
                   shouldResetMapView: $shouldResetMapView,
                   portugalRegion: portugalRegion)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack {
                        // Map Type Picker
                        Picker("Map Type", selection: $mapType) {
                            Text("Standard").tag(MKMapType.standard)
                            Text("Satellite").tag(MKMapType.satellite)
                            Text("Hybrid").tag(MKMapType.hybrid)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                        .background(Color(.systemBackground).opacity(0.8))
                        
                        // Search Bar
                        SearchBar(searchText: $searchText, isSearching: $isSearching)
                            .padding(.top, 2)
                        
                        if isSearching {
                            // Search Results
                            SearchResultsView(
                                dataService: dataService,
                                searchText: $searchText,
                                selectedCastle: $selectedCastle,
                                isSearching: $isSearching
                            )
                            .frame(height: min(300, CGFloat(min(dataService.searchCastles(query: searchText).count, 10) * 44 + 44)))
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.move(edge: .top))
                        }
                        
                        Spacer()
                    }
                )
            
            // Bottom Controls when a castle is selected
            if let selectedCastle = selectedCastle {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Visit/Unvisit Button - Now centered since Info button is removed
                        Button(action: {
                            dataService.toggleVisitedStatus(for: selectedCastle)
                            // Just clear the selected castle, don't reset the map view
                            // This will trigger our new behavior to restore previous map region
                            self.selectedCastle = nil
                        }) {
                            HStack {
                                Image(systemName: selectedCastle.isVisited ? "xmark.circle.fill" : "checkmark.circle.fill")
                                Text(selectedCastle.isVisited ? "Mark Not Visited" : "Mark Visited")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(selectedCastle.isVisited ? .red : .green)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            
            // Visited Castles Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showVisitedCastles = true
                    }) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 24))
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, selectedCastle != nil ? 100 : 30)
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            if let selectedCastle = selectedCastle, 
               let wikipediaURL = selectedCastle.wikipediaLink {
                // Always use Safari View Controller for better reliability
                NavigationView {
                    SafariView(url: wikipediaURL)
                        .edgesIgnoringSafeArea(.all)
                        .navigationTitle(selectedCastle.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .onDisappear {
                    showFallbackSafari = false
                    webViewErrorOccurred = false
                }
            } else {
                // Show an informative message when no valid URL is available
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding(.bottom, 20)
                    
                    Text("No Wikipedia Information Available")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    if let castleName = selectedCastle?.name {
                        Text("Could not load information for \(castleName)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Close") {
                        showInfoSheet = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showVisitedCastles) {
            VisitedCastlesView(dataService: dataService, selectedCastle: $selectedCastle)
        }
        .onAppear {
            // Set the map type
            NotificationCenter.default.post(
                name: NSNotification.Name("MapTypeChanged"),
                object: nil,
                userInfo: ["mapType": mapType.rawValue]
            )
        }
        .onChange(of: mapType) { newValue in
            // Update map type when changed
            NotificationCenter.default.post(
                name: NSNotification.Name("MapTypeChanged"),
                object: nil,
                userInfo: ["mapType": newValue.rawValue]
            )
        }
    }
} 