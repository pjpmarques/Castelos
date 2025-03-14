/**
 * CastleAnnotation.swift
 * 
 * Contains classes for rendering castle markers on the map.
 * This file defines both the annotation data model and its visual representation.
 */
import Foundation
import MapKit
import SwiftUI

/**
 * CastleAnnotation - A map annotation representing a castle on the map
 * 
 * This class adapts our Castle model to be compatible with MapKit's annotation system.
 * It implements the MKAnnotation protocol to allow displaying castles on the map.
 */
class CastleAnnotation: NSObject, MKAnnotation {
    // Reference to the castle model this annotation represents
    let castle: Castle
    
    // Required by MKAnnotation protocol - specifies the location on the map
    let coordinate: CLLocationCoordinate2D
    
    // Title that appears in the callout when the annotation is selected
    let title: String?
    
    // Initialize with a castle model
    init(castle: Castle) {
        self.castle = castle
        self.coordinate = castle.coordinate
        self.title = castle.name
        super.init()
    }
}

/**
 * CastleAnnotationView - Visual representation of a castle on the map
 * 
 * This custom annotation view:
 * - Uses a castle turret icon as the marker glyph
 * - Changes color based on visited status (brown for unvisited, green for visited)
 * - Provides an information button to access Wikipedia details
 * - Supports callouts when tapped
 */
class CastleAnnotationView: MKMarkerAnnotationView {
    // Identifier for reusing annotation views (improves performance)
    static let reuseIdentifier = "CastleAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupMarker()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMarker()
    }
    
    /**
     * Configure the appearance and behavior of the castle marker
     * 
     * Sets up:
     * - The castle turret icon as the marker glyph
     * - Color based on visit status
     * - Callout display and accessory view (info button)
     */
    private func setupMarker() {
        glyphImage = UIImage(systemName: "castle.turret.fill")
        markerTintColor = .systemBrown
        
        if let castleAnnotation = annotation as? CastleAnnotation {
            if castleAnnotation.castle.isVisited {
                markerTintColor = .systemGreen
            }
        }
        
        canShowCallout = true
        
        let infoButton = UIButton(type: .detailDisclosure)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        rightCalloutAccessoryView = infoButton
    }
    
    /**
     * Updates the annotation appearance just before it's displayed
     * 
     * This ensures the marker color is up-to-date with the castle's visited status
     * whenever the annotation is about to be shown on screen.
     */
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let castleAnnotation = annotation as? CastleAnnotation {
            markerTintColor = castleAnnotation.castle.isVisited ? .systemGreen : .systemBrown
        }
    }
} 