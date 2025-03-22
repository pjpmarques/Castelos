# Portuguese Fortifications/Castles Data Extractor

This project consists of two Python scripts:

1. `generate_castles_csv.py`: Scrapes a Wikipedia page to generate a CSV file with information about Portuguese fortifications/castles.
2. `validate_links.py`: Validates the links in the generated CSV file.

## Features

- Parallel processing for faster data collection and validation
- Uses Wikidata API to retrieve accurate geographic coordinates
- Generates Google Maps links for each fortification
- Validates all links to ensure they are accessible

## Requirements

- Python 3.6 or higher
- Required Python packages (install using `pip install -r requirements.txt`):
  - requests
  - beautifulsoup4

## Usage

### Step 1: Install dependencies

```bash
pip install -r requirements.txt
```

### Step 2: Generate the CSV file

```bash
python generate_castles_csv.py
```

This will create a file named `portuguese_fortifications.csv` with the following columns:
- Castle Name
- Latitude
- Longitude
- Google Maps Link
- Wikipedia Link

The script processes multiple fortifications in parallel, significantly speeding up the data collection process.

### Step 3: Validate the links

```bash
python validate_links.py
```

This will check each link in the CSV file and output whether they are valid or not. The validation is performed in parallel for faster processing.

## Notes

- The scripts include a short delay (100ms) between requests to be respectful to the servers.
- Only fortifications with valid coordinates will be included in the CSV file.
- The script uses the Wikidata API to get coordinates, which is more reliable than extracting them directly from Wikipedia pages. 