/**
 * MapView.swift
 * 
 * Core map component that displays castles on an interactive map.
 * Handles map display, interactions, annotations, and zoom behaviors.
 */
import SwiftUI
import MapKit

/**
 * MapView - Interactive map displaying Portuguese castles
 *
 * This SwiftUI wrapper around MKMapView handles:
 * - Displaying castle annotations on the map
 * - Handling user interactions (taps, selections)
 * - Managing zoom levels and map regions
 * - Preserving zoom state when deselecting castles
 * - Supporting user location tracking
 */
struct MapView: UIViewRepresentable {
    @ObservedObject var dataService: CastleDataService
    @Binding var selectedCastle: Castle?
    @Binding var showInfoSheet: Bool
    @Binding var shouldResetMapView: Bool
    @Binding var centerOnUserLocation: Bool
    let portugalRegion: MKCoordinateRegion
    
    /**
     * Creates the underlying MKMapView instance
     *
     * Sets up the initial map configuration including:
     * - Map region (initially showing all of Portugal)
     * - Map delegate for handling interactions
     * - User location display
     * - Custom castle annotation views
     * - Touch handling
     */
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
    
    /**
     * Updates the map view when bound variables change
     *
     * Handles several different update scenarios:
     * 1. Map reset - Returns to the full Portugal view
     * 2. User location centering - Focuses on user's current location
     * 3. Castle selection - Zooms to selected castle and shows its annotation
     * 4. Castle deselection - Returns to previous map region before selection
     *
     * Smart zoom behavior ensures the map maintains appropriate zoom levels
     * when interacting with castles.
     */
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
    
    /**
     * Updates the castle annotations displayed on the map
     *
     * This method:
     * - Removes existing castle annotations
     * - Creates new annotations from the current castle data
     * - Adds them to the map
     *
     * This ensures the map always shows the current state of castle data.
     */
    private func updateAnnotations(mapView: MKMapView) {
        // Remove existing annotations
        let existingAnnotations = mapView.annotations.compactMap { $0 as? CastleAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let annotations = dataService.castles.map { CastleAnnotation(castle: $0) }
        mapView.addAnnotations(annotations)
    }
    
    /**
     * Creates the coordinator that bridges UIKit and SwiftUI
     *
     * The coordinator handles map delegate methods and user interactions.
     */
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /**
     * Coordinator class - Handles map delegate methods and user interactions
     *
     * This class is responsible for:
     * - Responding to map interactions (taps, selection)
     * - Managing annotation views
     * - Tracking state for smart zoom behavior
     * - Handling map type changes
     */
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        weak var mapView: MKMapView?
        
        // Smart zoom tracking properties
        var previousMapRegion: MKCoordinateRegion?
        var previousSelectedCastle: Castle?
        
        // Flag to prevent selection loops
        var isHandlingSelection = false
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        /**
         * Creates annotation views for castles
         *
         * Returns a custom CastleAnnotationView for castle annotations,
         * or nil for the user location annotation (to use default blue dot).
         */
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
                
                // Ensure the marker is properly configured
                // This will help maintain the correct appearance during zoom
                annotationView.glyphImage = UIImage(systemName: "building.columns.fill")
                annotationView.markerTintColor = castleAnnotation.castle.isVisited ? .systemGreen : .systemBrown
                
                return annotationView
            }
            
            return nil
        }
        
        /**
         * Handles castle annotation selection
         *
         * When a castle marker is tapped:
         * - Prevents selection loops with isHandlingSelection flag
         * - Stores the current map region for smart zoom behavior
         * - Updates the selected castle in the parent view
         */
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
        
        /**
         * Handles castle annotation deselection
         *
         * When a castle marker is deselected:
         * - Prevents deselection loops with isHandlingSelection flag
         * - Clears the selected castle in the parent view
         * - The map will restore previous region in updateUIView
         */
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
        
        /**
         * Handles taps on a castle's callout accessory buttons
         *
         * Determines which button was tapped and responds accordingly:
         * - Left button (car): Opens Apple Maps with directions to the castle
         * - Right button (info): Shows the Wikipedia info sheet for the castle
         */
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let castleAnnotation = view.annotation as? CastleAnnotation else { return }
            parent.selectedCastle = castleAnnotation.castle
            
            // Check which accessory was tapped
            if control == view.leftCalloutAccessoryView {
                // Car button - open Maps app with driving directions
                let castle = castleAnnotation.castle
                
                // Create a Maps URL for directions
                let latitude = castle.coordinate.latitude
                let longitude = castle.coordinate.longitude
                let name = castle.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                
                // Format: maps://?daddr=lat,long&dirflg=d
                // dirflg=d means driving directions
                let urlString = "maps://?daddr=\(latitude),\(longitude)&dirflg=d&dname=\(name)"
                
                if let url = URL(string: urlString) {
                    // Use the modern, non-deprecated API
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if control == view.rightCalloutAccessoryView {
                // Info button - show Wikipedia sheet
                parent.showInfoSheet = true
            }
        }
        
        /**
         * Handles map type changes (Standard, Satellite, Hybrid)
         *
         * Receives notifications from ContentView when the user changes map type.
         */
        @objc func mapTypeChanged(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let mapTypeRawValue = userInfo["mapType"] as? UInt,
                  let mapType = MKMapType(rawValue: mapTypeRawValue) else {
                return
            }
            
            // Update the map type
            mapView?.mapType = mapType
        }
        
        /**
         * Handles taps on the map (outside of annotations)
         *
         * When tapping on an empty area of the map:
         * - Checks if the tap is outside of any annotation
         * - If so and a castle is selected, deselects it
         * - Prevents tap handling loops with isHandlingSelection flag
         */
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
        
        /**
         * Controls whether a gesture recognizer should receive a touch
         *
         * Prevents the tap gesture from capturing taps on annotation views,
         * allowing those to be handled by the map's annotation selection instead.
         */
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