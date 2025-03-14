# Portuguese Castles App Development Guide

This document provides a comprehensive set of prompts and specifications to recreate the Portuguese Castles app using Claude 3.7. Follow these instructions to build the app from scratch.

## Project Overview

The Portuguese Castles app is an iOS application built with SwiftUI that allows users to explore historical castles and fortifications throughout Portugal. Key features include:

- Interactive map showing the locations of Portuguese castles
- Detailed castle information via Wikipedia integration
- Search functionality for finding specific castles
- Ability to mark castles as visited/not visited
- User location tracking
- Multiple map view types (Standard, Satellite, Hybrid)

## Phase 1: Project Setup and Data Model

### Initial Setup Prompt

"Create a new Swift project for iOS called 'Portuguese Castles' using SwiftUI. This app will allow users to explore historical castles and fortifications in Portugal. Set up the initial project structure with appropriate groups for models, views, and services."

### Data Model Specifications

The app requires two primary data models:

1. **Castle Model**
   ```swift
   struct Castle: Identifiable, Equatable {
       let id = UUID()
       let name: String
       let coordinate: CLLocationCoordinate2D
       let googleMapsLink: URL?
       let wikipediaLink: URL?
       var isVisited: Bool = false
       
       // Equatable implementation and MKMapItem extension
   }
   ```

2. **Castle Annotation Model** (for map display)
   ```swift
   class CastleAnnotation: NSObject, MKAnnotation {
       let castle: Castle
       let coordinate: CLLocationCoordinate2D
       let title: String?
       
       init(castle: Castle) {
           self.castle = castle
           self.coordinate = castle.coordinate
           self.title = castle.name
       }
   }
   ```

### Data Service Prompt

"Create a CastleDataService class that will be responsible for loading castle data from a CSV file, managing the list of castles, tracking visited castles, and providing search functionality. The service should:
1. Load castle data from a CSV file in the app bundle
2. Store and retrieve visited castle status using UserDefaults
3. Provide methods for toggling visited status
4. Implement search functionality that returns castles sorted alphabetically
5. Use the Observable object pattern to publish changes to subscribers"

## Phase 2: Core Map Functionality

### MapView Implementation Prompt

"Create a MapView component using UIViewRepresentable to display an interactive map of Portugal with castle annotations. The MapView should:
1. Display castle locations using custom annotations
2. Allow selecting castles to view details
3. Implement smart zoom behavior that preserves previous zoom levels
4. Support user location tracking
5. Handle map taps and deselection of castles
6. Customize annotation appearance based on visited status (green for visited, brown for unvisited)"

### Custom Annotation View Prompt

"Implement a custom CastleAnnotationView class that inherits from MKMarkerAnnotationView to display castle markers with:
1. A castle turret icon as the marker glyph
2. Color changes based on visited status (green for visited, brown for unvisited)
3. Information button in the callout
4. Proper handling of selection state updates"

## Phase 3: User Interface Components

### ContentView Prompt

"Create the main ContentView that serves as the app's primary interface. It should:
1. Integrate the MapView as the main background
2. Include a search bar at the top
3. Provide map type selection (Standard, Satellite, Hybrid)
4. Add floating action buttons for user location and visited castles list
5. Implement a bottom sheet for castle details when selected
6. Handle different UI states (searching, castle selected, etc.)"

### SearchBar Component Prompt

"Implement a custom SearchBar component that:
1. Accepts user input for castle searches
2. Shows/hides a cancel button based on search state
3. Provides clear button functionality when text is entered
4. Handles keyboard dismissal
5. Reports search state changes back to parent views"

### SearchResultsView Prompt

"Create a SearchResultsView that displays filtered castle search results. It should:
1. Show all castles alphabetically when no search text is entered
2. Filter castles based on search text
3. Display visited status with a checkmark icon
4. Handle selection to transition to the map view
5. Have dynamic height based on number of results
6. Clear search and dismiss keyboard on selection"

### VisitedCastlesView Prompt

"Implement a VisitedCastlesView component that:
1. Displays a list of castles marked as visited
2. Shows appropriate messaging when no castles have been visited
3. Allows selecting a castle to view it on the map
4. Includes a close button to dismiss the view
5. Provides visual indicators for visited status"

## Phase 4: Web Content Integration

### WebView Component Prompt

"Create a WebView component using UIViewRepresentable to display Wikipedia content about selected castles. The WebView should:
1. Load URLs with proper configuration
2. Handle loading errors with retry logic
3. Provide a fallback to Safari when internal WebView fails
4. Support standard web navigation gestures
5. Include error state reporting"

### SafariView Fallback Prompt

"Implement a SafariView component that serves as a fallback when WebView fails. It should:
1. Use SFSafariViewController to display web content
2. Handle proper configuration and dismissal
3. Provide a consistent user experience with the native Safari interface"

## Phase 5: Data Management and Persistence

### CSV Parsing Prompt

"Implement a robust CSV parsing function in the CastleDataService that:
1. Handles quoted fields properly
2. Manages malformed data gracefully
3. Extracts castle information (name, coordinates, links)
4. Creates Castle instances from the parsed data
5. Provides appropriate debugging information"

### UserDefaults Storage Prompt

"Implement visited castle persistence using UserDefaults:
1. Store only castle names for efficiency
2. Load visited status on app launch
3. Maintain a separate array of visited castles for quick access
4. Synchronize the main castle list with visited status
5. Save changes immediately when status is toggled"

## Phase 6: Interaction Flow and Behavior

### Castle Selection Flow Prompt

"Implement the castle selection flow that:
1. Zooms the map to the selected castle
2. Shows castle information with proper animation
3. Provides a button to toggle visited status
4. Preserves previous map state when deselecting
5. Handles transitions between different castles"

### Search Interaction Prompt

"Implement search interaction behavior:
1. Show all castles alphabetically when no search text is entered
2. Filter results instantly as the user types
3. Hide floating controls during active search
4. Handle search dismissal with proper state restoration
5. Ensure instant (non-animated) updates to search results"

### Location Tracking Prompt

"Implement user location tracking:
1. Request appropriate location permissions
2. Add a button to center on user location
3. Configure proper zoom level when centering
4. Handle authorization status changes gracefully
5. Provide visual feedback during location acquisition"

## Phase 7: UI Refinement and Testing

### Animation and Transition Prompt

"Refine animations and transitions:
1. Ensure search results appear/disappear without animation
2. Implement smooth transitions between map states
3. Add subtle animations for button interactions
4. Ensure proper keyboard handling with animations
5. Optimize for performance during transitions"

### Error Handling Prompt

"Implement comprehensive error handling:
1. Handle missing or malformed CSV data
2. Provide fallbacks for web content loading issues
3. Manage location permissions gracefully
4. Handle edge cases in search functionality
5. Provide user feedback for error conditions"

### Documentation Prompt

"Add comprehensive documentation:
1. Include header comments for each file explaining its purpose
2. Document all classes, structs, and protocols
3. Add detailed comments for complex functions
4. Document state management and data flow
5. Provide comments for UI layout sections
6. Ensure all user interactions are documented"

## Sample CSV Data Structure

The app requires a CSV file named "portuguese_fortifications.csv" with the following columns:
1. Castle name
2. Latitude
3. Longitude
4. Google Maps URL
5. Wikipedia URL

Example:
```
Name,Latitude,Longitude,Google Maps Link,Wikipedia Link
"Castelo de São Jorge",38.7139,-9.1334,"https://maps.google.com/?q=38.7139,-9.1334","https://en.wikipedia.org/wiki/São_Jorge_Castle"
```

## Build Sequence Instructions

Follow this specific order to build the app:

1. Set up project and create data models (Castle.swift)
2. Implement the CastleDataService for data management
3. Create the map-related components (MapView, CastleAnnotation)
4. Build the core UI components (ContentView structure)
5. Add search functionality (SearchBar, SearchResultsView)
6. Implement the visited castles feature (VisitedCastlesView)
7. Create web content display (WebView, SafariView)
8. Connect all components and ensure proper state management
9. Add animations, transitions, and polish the UI
10. Document all code with comprehensive comments

## UI/UX Requirements

- Clean, minimal interface with focus on the map
- Floating circular buttons for main actions
- Semi-transparent controls that don't obscure the map
- Proper spacing and padding throughout the UI
- Responsive layout that adapts to different screen sizes
- Clear visual indicators for visited/unvisited states
- Smooth transitions between UI states
- Proper handling of keyboard appearance/disappearance

## Testing Checklist

Before finalizing implementation, verify:

1. Castle data loads correctly from CSV
2. Search functionality works for partial name matches
3. Visited castle status persists between app launches
4. Map annotations update color when visited status changes
5. Web content loads properly in both WebView and fallback
6. User location tracking works correctly
7. All animations and transitions are smooth
8. App responds properly to different device orientations
9. UI elements are properly positioned on different devices
10. All error cases are handled gracefully

This specification provides a comprehensive blueprint for recreating the Portuguese Castles app from scratch. 