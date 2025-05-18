# Portuguese Castles Explorer

An iOS application that allows users to explore and track visits to castles and fortifications across Portugal. This interactive map-based app helps tourists and history enthusiasts discover Portugal's rich architectural heritage.

## Features

- **Interactive Map**: View all Portuguese castles and fortifications on an interactive map
- **Advanced Search**: Quickly find castles by name with instant alphabetically sorted results
- **Location Tracking**: Center the map on your current location to find nearby castles
- **Visit Tracking**: Mark castles as visited and maintain a personal visited castles list
- **Information Access**: Access detailed Wikipedia information about each castle
- **Multiple Map Views**: Choose between Standard, Satellite, and Hybrid map views
- **Smart Zoom Behavior**: Intelligently maintains zoom levels when interacting with the map
- **Intuitive UI**: Clean, modern interface following iOS design standards

## Key User Interactions

### Map Navigation and Viewing
- **Map Controls**: Pan and zoom the map to explore Portugal's castles
- **Zoom Persistence**: The app intelligently preserves your zoom level when deselecting castles
- **User Location**: Tap the location button to center the map on your current position
- **Map Type Selection**: Switch between Standard, Satellite, and Hybrid views using the top segmented control

### Castle Discovery
- **Visual Indicators**: 
  - Brown markers: Castles you haven't visited
  - Green markers: Castles you've already visited
  - Blue dot: Your current location on the map
- **Direct Selection**: Tap on any castle marker to select it
- **Information Button**: Each selected castle shows an information (i) button in its callout
- **Search Functionality**: 
  - Use the search bar to find castles by name
  - All castles are shown alphabetically when first tapping the search bar
  - Results filter instantly as you type
  - Castles you've visited are indicated with a green checkmark

### Castle Interaction
- **Selecting Castles**:
  - Tap on a map marker to select a castle
  - The map zooms to focus on the selected castle
  - Select from search results to quickly find and focus on specific castles
- **Castle Actions**:
  - **Visit Management**: Toggle a castle's visited status with the "Mark Visited" / "Mark Not Visited" button
  - **Information Access**: Tap the (i) button in the callout to view the castle's Wikipedia page
- **Deselecting**: Tap anywhere on the map outside castle markers to deselect and return to your previous view

### Visited Castles Management
- **Visited List**: Access your collection of visited castles by tapping the list button
- **Quick Navigation**: Tap any castle in the list to immediately view it on the map
- **Progress Tracking**: Monitor your exploration journey through Portugal's historical sites

## Technical Specifications

### Requirements
- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+
- Internet connection for loading Wikipedia pages

### Architecture
- **SwiftUI**: Modern declarative user interface
- **MapKit**: Native Apple mapping framework for smooth map interactions
- **CoreLocation**: User location services with privacy-focused permissions
- **Local Storage**: Visit data persisted using UserDefaults

### Privacy Considerations
- **Location Services**: Your location is only used to show your position on the map
- **Local Data Storage**: Visited castles are stored locally on your device only
- **No Tracking**: The app doesn't collect user data or send information to external servers

## Installation

1. Clone or download the repository
2. Open the project in Xcode by double-clicking the `PortugueseCastles.xcodeproj` file
3. Select a simulator or connect your iOS device
4. Press the "Play" button or use Command+R to build and run the application

## Data Source

The app uses a comprehensive CSV dataset containing information about Portuguese castles and fortifications, including:
- Castle Name
- Precise Latitude/Longitude coordinates
- Google Maps links
- Wikipedia links for additional information

## Future Enhancements

Potential future enhancements might include:
- Routing and directions to castles
- Offline map support
- Additional historical information
- User photos and notes
- Castle ratings and reviews
- Social sharing functionality

## Contributing

Contributions to improve the app are welcome. Please feel free to submit pull requests or open issues to suggest improvements or report bugs.

## License

This project is available as open source under the terms of the Apache 2.0 License. 