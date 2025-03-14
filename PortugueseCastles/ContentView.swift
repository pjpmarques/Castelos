/**
 * ContentView.swift
 * 
 * Main view of the Portuguese Castles app.
 * Coordinates all UI components and user interactions.
 */
import SwiftUI
import MapKit
import CoreLocation

/**
 * ContentView - Main view controller for the app
 * 
 * This view:
 * - Integrates all app components (map, search, controls)
 * - Manages the overall app state
 * - Handles user interactions
 * - Coordinates between views
 */
struct ContentView: View {
    // MARK: - State Management
    
    // Core data service for castle information
    @StateObject private var dataService = CastleDataService()
    
    // Castle selection state
    @State private var selectedCastle: Castle?
    @State private var showInfoSheet = false
    
    // UI state management
    @State private var showVisitedCastles = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var mapType: MKMapType = .standard
    @State private var shouldResetMapView = false
    @State private var showFallbackSafari = false
    @State private var webViewErrorOccurred = false
    
    // Location related state
    @State private var centerOnUserLocation = false
    @State private var locationManager = CLLocationManager()
    
    // Maximum number of castles to show in search results when no query is entered
    private let maxInitialSearchResults = 15
    
    // Portugal's bounding box coordinates for resetting the map
    // Adjusted to shift center point slightly southward for better viewing
    private let portugalRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.0, longitude: -8.0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    
    /**
     * Calculates the appropriate height for search results based on the number of results
     * 
     * Limits the height to prevent excessive space usage for large result sets,
     * and uses a different limit for initial (empty query) vs. search results.
     */
    private func calculateSearchResultsHeight() -> CGFloat {
        let resultsCount = dataService.searchCastles(query: searchText).count
        let limitedResultsCount = searchText.isEmpty ? min(resultsCount, maxInitialSearchResults) : min(resultsCount, 10)
        return min(300, CGFloat(limitedResultsCount * 44))
    }
    
    // MARK: - View Body
    
    var body: some View {
        // Main ZStack layout for layering UI elements
        ZStack(alignment: .top) {
            // MARK: Map Layer
            
            // Map View - The base layer showing all castles
            MapView(dataService: dataService, 
                   selectedCastle: $selectedCastle, 
                   showInfoSheet: $showInfoSheet,
                   shouldResetMapView: $shouldResetMapView,
                   centerOnUserLocation: $centerOnUserLocation,
                   portugalRegion: portugalRegion)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack {
                        // MARK: Top Controls Layer
                        
                        // Map Type Picker - Allows switching between map views
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
                        
                        // Search Bar - For finding castles
                        SearchBar(searchText: $searchText, isSearching: $isSearching)
                            .padding(.top, 2)
                        
                        // Display search results without animation
                        Group {
                            if isSearching {
                                // Search Results - Shows matching castles
                                SearchResultsView(
                                    dataService: dataService,
                                    searchText: $searchText,
                                    selectedCastle: $selectedCastle,
                                    isSearching: $isSearching
                                )
                                .frame(height: calculateSearchResultsHeight())
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                )
            
            // MARK: Castle Selection Controls Layer
            
            // Bottom Controls when a castle is selected
            if let selectedCastle = selectedCastle {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Visit/Unvisit Button - Allows marking castles as visited
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
            
            // MARK: Floating Controls Layer
            
            // Only show floating controls when not searching
            if !isSearching {
                // Bottom right buttons for map actions
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Location Button - Centers map on user location
                            Button(action: {
                                // Request location authorization if not determined
                                if locationManager.authorizationStatus == .notDetermined {
                                    locationManager.requestWhenInUseAuthorization()
                                }
                                
                                // Center on user location
                                centerOnUserLocation = true
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 24))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            // Visited Castles Button - Shows list of visited castles
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
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, selectedCastle != nil ? 100 : 30)
                    }
                }
            }
        }
        // MARK: Modal Sheets
        
        // Castle Information Sheet - Shows Wikipedia information
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
        
        // Visited Castles Sheet - Shows list of visited castles
        .sheet(isPresented: $showVisitedCastles) {
            VisitedCastlesView(dataService: dataService, selectedCastle: $selectedCastle)
        }
        
        // MARK: Lifecycle Events
        
        .onAppear {
            // Set the map type
            NotificationCenter.default.post(
                name: NSNotification.Name("MapTypeChanged"),
                object: nil,
                userInfo: ["mapType": mapType.rawValue]
            )
            
            // Initialize the location manager
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
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