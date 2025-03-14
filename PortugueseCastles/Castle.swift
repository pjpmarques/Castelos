/**
 * Castle.swift
 * 
 * The core data model representing a Portuguese castle or fortification
 * Contains essential information for displaying and interacting with castles on the map
 */
import Foundation
import MapKit

/**
 * Castle model - Represents a Portuguese castle or fortification
 *
 * This struct stores all necessary information about a historical castle including:
 * - Unique identification (through the identifiable protocol)
 * - Geographical positioning (coordinates)
 * - External reference links (Google Maps, Wikipedia)
 * - Visit status tracking
 */
struct Castle: Identifiable, Equatable {
    // Unique identifier for the Castle instance
    let id = UUID()
    
    // Basic information about the castle
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    // External reference links
    let googleMapsLink: URL?
    let wikipediaLink: URL?
    
    // Tracks whether the user has visited this castle
    // This is mutable to allow toggling the visited status
    var isVisited: Bool = false
    
    static func == (lhs: Castle, rhs: Castle) -> Bool {
        lhs.id == rhs.id
    }
}

extension Castle {
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }
} 