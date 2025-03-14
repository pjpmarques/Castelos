import Foundation
import MapKit

struct Castle: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let googleMapsLink: URL?
    let wikipediaLink: URL?
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