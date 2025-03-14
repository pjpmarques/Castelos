import Foundation
import MapKit
import SwiftUI

class CastleAnnotation: NSObject, MKAnnotation {
    let castle: Castle
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    init(castle: Castle) {
        self.castle = castle
        self.coordinate = castle.coordinate
        self.title = castle.name
        super.init()
    }
}

class CastleAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "CastleAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupMarker()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMarker()
    }
    
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
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        if let castleAnnotation = annotation as? CastleAnnotation {
            markerTintColor = castleAnnotation.castle.isVisited ? .systemGreen : .systemBrown
        }
    }
} 