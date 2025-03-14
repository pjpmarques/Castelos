import Foundation
import MapKit
import Combine

class CastleDataService: ObservableObject {
    @Published var castles: [Castle] = []
    @Published var visitedCastles: [Castle] = []
    
    private let userDefaultsKey = "visitedCastles"
    
    init() {
        loadCastlesFromCSV()
        loadVisitedCastlesFromUserDefaults()
    }
    
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
    
    func toggleVisitedStatus(for castle: Castle) {
        if let index = castles.firstIndex(where: { $0.name == castle.name }) {
            castles[index].isVisited.toggle()
            
            if castles[index].isVisited {
                visitedCastles.append(castles[index])
            } else {
                visitedCastles.removeAll { $0.name == castle.name }
            }
            
            saveVisitedCastlesToUserDefaults()
        }
    }
    
    private func saveVisitedCastlesToUserDefaults() {
        let visitedCastleNames = visitedCastles.map { $0.name }
        UserDefaults.standard.set(visitedCastleNames, forKey: userDefaultsKey)
    }
    
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