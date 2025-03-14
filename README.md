# Portuguese Castles Explorer

An iOS application that allows users to explore and track visits to castles and fortifications across Portugal.

## Features

- Interactive map of Portugal showing all castles and fortifications
- Search functionality to find specific castles
- Mark castles as visited/not visited
- View detailed information about each castle via Wikipedia
- View a list of all visited castles
- Different map views (Standard, Satellite, Hybrid)

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

## Installation

1. Open the project in Xcode by double-clicking the `PortugueseCastles.xcodeproj` file
2. Select a simulator or connect your iOS device
3. Press the "Play" button or use Command+R to build and run the application

## Usage

### Main Map View
- The app opens with a map of Portugal showing all castles as markers
- Brown markers indicate castles you haven't visited
- Green markers indicate castles you have visited

### Searching for Castles
- Use the search bar at the top to find specific castles
- As you type, matching castles will appear in a dropdown list
- Castles you've visited will have a green checkmark next to their name

### Castle Details
- Tap on a castle marker to select it
- When a castle is selected, two buttons appear at the bottom:
  - "Mark Visited" / "Mark Not Visited" - Toggle the visited status
  - "Info" - Open the Wikipedia page for the castle

### Viewing Visited Castles
- Tap the list button in the bottom right corner to see all castles you've visited
- From this list, you can tap on a castle to view it on the map

### Changing Map Type
- Use the segmented control at the top to switch between Standard, Satellite, and Hybrid map views

## Data Source

The app uses a CSV file containing information about Portuguese castles and fortifications, including:
- Castle Name
- Latitude/Longitude coordinates
- Google Maps link
- Wikipedia link

## Privacy

The app stores your visited castles locally on your device using UserDefaults. No data is sent to external servers. 