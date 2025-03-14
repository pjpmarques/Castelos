import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var dataService: CastleDataService
    @Binding var selectedCastle: Castle?
    @Binding var showInfoSheet: Bool
    @Binding var shouldResetMapView: Bool
    @Binding var centerOnUserLocation: Bool
    let portugalRegion: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = portugalRegion
        mapView.showsCompass = true
        
        // Enable showing user location
        mapView.showsUserLocation = true
        
        mapView.register(
            CastleAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: CastleAnnotationView.reuseIdentifier
        )
        
        // Add tap gesture recognizer to handle taps outside annotations
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        // Listen for map type changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.mapTypeChanged(_:)),
            name: NSNotification.Name("MapTypeChanged"),
            object: nil
        )
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateAnnotations(mapView: mapView)
        
        if shouldResetMapView {
            // Reset the map to show all of Portugal
            mapView.setRegion(portugalRegion, animated: true)
            DispatchQueue.main.async {
                shouldResetMapView = false
            }
            
            // Deselect any selected annotation
            if let selectedAnnotation = mapView.selectedAnnotations.first {
                mapView.deselectAnnotation(selectedAnnotation, animated: true)
            }
            
            // Clear previous state
            context.coordinator.previousSelectedCastle = nil
            context.coordinator.previousMapRegion = nil
        } else if centerOnUserLocation {
            // Center on user location when requested
            if let userLocation = mapView.userLocation.location {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                mapView.setRegion(region, animated: true)
            }
            
            // Reset the flag
            DispatchQueue.main.async {
                centerOnUserLocation = false
            }
        } else if let selectedCastle = selectedCastle {
            // Check if this is a new castle selection or the same one
            let isNewSelection = context.coordinator.previousSelectedCastle == nil || 
                                context.coordinator.previousSelectedCastle?.name != selectedCastle.name
            
            if isNewSelection {
                // Store the current region before changing it, but only if it's a new selection
                context.coordinator.previousMapRegion = mapView.region
                context.coordinator.previousSelectedCastle = selectedCastle
                
                // Set the new region focused on the castle
                let region = MKCoordinateRegion(
                    center: selectedCastle.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                mapView.setRegion(region, animated: true)
            }
            
            // Find and select the annotation for the selected castle if it's not already selected
            if let annotation = mapView.annotations.first(where: { 
                ($0 as? CastleAnnotation)?.castle.name == selectedCastle.name 
            }) {
                // Check if this annotation is already selected
                let isAlreadySelected = mapView.selectedAnnotations.contains(where: { $0 === annotation })
                if !isAlreadySelected {
                    mapView.selectAnnotation(annotation, animated: true)
                }
            }
        } else {
            // If no castle is selected and we had a previously selected castle
            if context.coordinator.previousSelectedCastle != nil {
                // Deselect any selected annotation first
                if let selectedAnnotation = mapView.selectedAnnotations.first {
                    mapView.deselectAnnotation(selectedAnnotation, animated: false)
                }
                
                // Restore the previous map region
                if let previousRegion = context.coordinator.previousMapRegion {
                    mapView.setRegion(previousRegion, animated: true)
                }
                
                // Clear the previous state
                context.coordinator.previousSelectedCastle = nil
            }
        }
    }
    
    private func updateAnnotations(mapView: MKMapView) {
        // Remove existing annotations
        let existingAnnotations = mapView.annotations.compactMap { $0 as? CastleAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let annotations = dataService.castles.map { CastleAnnotation(castle: $0) }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        weak var mapView: MKMapView?
        var previousMapRegion: MKCoordinateRegion?
        var previousSelectedCastle: Castle?
        // Flag to prevent selection loops
        var isHandlingSelection = false
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            self.mapView = mapView
            
            guard !annotation.isKind(of: MKUserLocation.self) else {
                return nil
            }
            
            if let castleAnnotation = annotation as? CastleAnnotation {
                let annotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: CastleAnnotationView.reuseIdentifier,
                    for: castleAnnotation
                ) as! CastleAnnotationView
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !isHandlingSelection, let castleAnnotation = view.annotation as? CastleAnnotation else { return }
            
            // Set flag to prevent selection loops
            isHandlingSelection = true
            
            // Store the current region before selecting a castle if we don't have a selected castle yet
            if parent.selectedCastle == nil {
                previousMapRegion = mapView.region
            }
            
            DispatchQueue.main.async {
                self.parent.selectedCastle = castleAnnotation.castle
                // Reset flag after short delay to allow state to stabilize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isHandlingSelection = false
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            // Only process deselection if we're not in the middle of handling a selection
            guard !isHandlingSelection else { return }
            
            // Set flag to prevent selection loops
            isHandlingSelection = true
            
            // When an annotation is deselected, clear the selected castle
            DispatchQueue.main.async {
                self.parent.selectedCastle = nil
                
                // Reset flag after short delay to allow state to stabilize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isHandlingSelection = false
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let castleAnnotation = view.annotation as? CastleAnnotation else { return }
            parent.selectedCastle = castleAnnotation.castle
            parent.showInfoSheet = true
        }
        
        @objc func mapTypeChanged(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let mapTypeRawValue = userInfo["mapType"] as? UInt,
                  let mapType = MKMapType(rawValue: mapTypeRawValue) else {
                return
            }
            
            // Update the map type
            mapView?.mapType = mapType
        }
        
        @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
            if gestureRecognizer.state == .ended {
                // Don't process if we're in the middle of a selection/deselection 
                guard !isHandlingSelection else { return }
                
                // Get the map view
                guard let mapView = gestureRecognizer.view as? MKMapView else { return }
                
                // Get the tap location
                let point = gestureRecognizer.location(in: mapView)
                
                // Check if the tap is on an annotation
                let tappedOnAnnotation = mapView.annotations.contains(where: { 
                    guard let annotationView = mapView.view(for: $0) else { return false }
                    return annotationView.frame.contains(point)
                })
                
                // If no annotation was tapped and we have a selected castle, deselect it
                if !tappedOnAnnotation && parent.selectedCastle != nil {
                    isHandlingSelection = true
                    
                    DispatchQueue.main.async {
                        self.parent.selectedCastle = nil
                        
                        // Reset flag after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isHandlingSelection = false
                        }
                    }
                }
            }
        }
        
        // Implement UIGestureRecognizerDelegate to allow both tap gesture and annotation selection
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Allow the gesture to be recognized only if the touch is not on an annotation view
            if let mapView = gestureRecognizer.view as? MKMapView {
                let point = touch.location(in: mapView)
                for annotation in mapView.annotations {
                    guard let view = mapView.view(for: annotation) else { continue }
                    if view.frame.contains(point) {
                        // Touch is on an annotation view, don't recognize the gesture
                        return false
                    }
                }
            }
            // Touch is not on an annotation view, recognize the gesture
            return true
        }
    }
} 