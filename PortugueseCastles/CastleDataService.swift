/**
 * CastleDataService.swift
 * 
 * Central data management service for the app's castle information.
 * Handles loading, filtering, searching, and persistence of castle data.
 */
import Foundation
import MapKit
import Combine

/**
 * CastleDataService - Manages the app's castle data
 *
 * This service class is responsible for:
 * - Loading castle data from the CSV file
 * - Storing and retrieving visited castle status
 * - Providing search functionality across the castle data
 * - Publishing changes to subscribers through @Published properties
 */
class CastleDataService: ObservableObject {
    // Published properties allow SwiftUI views to react to data changes
    @Published var castles: [Castle] = []
    @Published var visitedCastles: [Castle] = []
    
    // Key used for storing visited castles in UserDefaults
    private let userDefaultsKey = "visitedCastles"
    
    /**
     * Initialize the data service
     * 
     * Loads castle data from CSV and retrieves any previously visited castles
     * from local storage.
     */
    init() {
        loadCastlesFromCSV()
        loadVisitedCastlesFromUserDefaults()
    }
    
    /**
     * Loads castle data from the included CSV file
     * 
     * This method:
     * - Locates and parses the CSV file containing castle information
     * - Handles CSV parsing with proper quote and delimiter handling
     * - Creates Castle objects for each valid row in the CSV
     * - Populates the castles array with the parsed data
     */
    private func loadCastlesFromCSV() {
        guard let path = Bundle.main.path(forResource: "portuguese_fortifications", ofType: "csv") else {
            print("CSV file not found")
            return
        }
        
        do {
            let csvContent = try String(contentsOfFile: path, encoding: .utf8)
            let rows = csvContent.components(separatedBy: .newlines)
            print("Total rows in CSV: \(rows.count)")
            
            // Special debugging flag for problematic castles
            let debugCastles = ["Castelo de Amieira", "Castelo de Amieira do Tejo", "Forte de São Roque"]
            
            // Skip the header row
            for i in 1..<rows.count {
                let row = rows[i]
                if row.isEmpty { continue }
                
                // Split at commas that are not within quotes
                var columns: [String] = []
                var currentColumn = ""
                var insideQuotes = false
                
                // Custom CSV parsing to handle quoted fields properly
                for char in row {
                    if char == "\"" {
                        insideQuotes = !insideQuotes
                        currentColumn.append(char) // Keep quotes for now
                    } else if char == "," && !insideQuotes {
                        columns.append(currentColumn)
                        currentColumn = ""
                    } else {
                        currentColumn.append(char)
                    }
                }
                columns.append(currentColumn) // Add the last column
                
                // Need at least 5 columns (name, lat, long, google maps, wikipedia)
                guard columns.count >= 5 else { continue }
                
                // Clean up columns by removing surrounding quotes and whitespace
                for j in 0..<columns.count {
                    columns[j] = columns[j].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Remove surrounding quotes if present
                    if columns[j].hasPrefix("\"") && columns[j].hasSuffix("\"") {
                        let startIndex = columns[j].index(after: columns[j].startIndex)
                        let endIndex = columns[j].index(before: columns[j].endIndex)
                        columns[j] = String(columns[j][startIndex..<endIndex])
                    }
                }
                
                let name = columns[0]
                
                // Extra debugging for specific castles
                let needsDebugging = debugCastles.contains(name)
                if needsDebugging {
                    print("SPECIAL DEBUG for \(name) (row \(i)):")
                    for (j, col) in columns.enumerated() {
                        print("  Column \(j): '\(col)'")
                    }
                }
                
                guard let latitude = Double(columns[1]),
                      let longitude = Double(columns[2]) else { continue }
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                // Create URLs directly from the clean columns
                let googleMapsLink = URL(string: columns[3])
                let wikipediaLink = URL(string: columns[4])
                
                if needsDebugging {
                    print("  Raw Wikipedia URL: '\(columns[4])'")
                    print("  Parsed Wikipedia URL: \(String(describing: wikipediaLink))")
                    
                    // Try alternative encoding if needed
                    if wikipediaLink == nil {
                        if let encoded = columns[4].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            print("  Tried encoded URL: '\(encoded)'")
                            print("  Result: \(URL(string: encoded) != nil ? "Success" : "Failed")")
                        }
                    }
                }
                
                let castle = Castle(
                    name: name,
                    coordinate: coordinate,
                    googleMapsLink: googleMapsLink,
                    wikipediaLink: wikipediaLink
                )
                
                castles.append(castle)
            }
            
            print("Successfully loaded \(castles.count) castles from CSV")
        } catch {
            print("Error reading CSV file: \(error)")
        }
    }
    
    /**
     * Retrieves the user's previously visited castles from local storage
     * 
     * This method:
     * - Reads the list of visited castle names from UserDefaults
     * - Updates the visited status of matching castles in the main collection
     * - Builds the visitedCastles array for easy access to just visited castles
     */
    private func loadVisitedCastlesFromUserDefaults() {
        if let visitedCastleNames = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            for i in 0..<castles.count {
                if visitedCastleNames.contains(castles[i].name) {
                    castles[i].isVisited = true
                    visitedCastles.append(castles[i])
                }
            }
        }
    }
    
    /**
     * Toggles whether a castle has been visited by the user
     * 
     * This method:
     * - Finds the castle in the main collection
     * - Toggles its visited status
     * - Updates the visitedCastles collection
     * - Persists the change to UserDefaults
     * 
     * @param castle The castle to toggle visited status for
     */
    func toggleVisitedStatus(for castle: Castle) {
        if let index = castles.firstIndex(where: { $0.name == castle.name }) {
            objectWillChange.send()

            castles[index].isVisited.toggle()

            if castles[index].isVisited {
                visitedCastles.append(castles[index])
            } else {
                visitedCastles.removeAll { $0.name == castle.name }
            }

            // Reassign arrays to trigger @Published updates
            castles = castles
            visitedCastles = visitedCastles

            saveVisitedCastlesToUserDefaults()
        }
    }
    
    /**
     * Saves the list of visited castle names to UserDefaults
     * 
     * Persists just the names of visited castles for efficient storage
     */
    private func saveVisitedCastlesToUserDefaults() {
        let visitedCastleNames = visitedCastles.map { $0.name }
        UserDefaults.standard.set(visitedCastleNames, forKey: userDefaultsKey)
    }
    
    /**
     * Searches castles based on a text query
     * 
     * When query is empty, returns all castles sorted alphabetically.
     * Otherwise, returns castles whose names contain the query string.
     * 
     * @param query The search text to filter castles by
     * @return Array of castles matching the search criteria, alphabetically sorted
     */
    func searchCastles(query: String) -> [Castle] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            // When no search query is provided, return all castles sorted alphabetically
            return castles.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
        
        // Safely filter castles based on search query
        return castles.filter { castle in
            guard let name = castle.name as String? else { return false }
            return name.lowercased().contains(trimmedQuery.lowercased())
        }.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }) // Sort results alphabetically
    }
} 