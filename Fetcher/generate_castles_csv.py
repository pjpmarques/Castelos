import requests
from bs4 import BeautifulSoup
import csv
import re
import time
import urllib.parse
import json
import concurrent.futures
import threading

# Create a lock for thread-safe CSV writing
csv_lock = threading.Lock()

def extract_proper_name_from_url(url, current_name):
    """Extract and clean the proper name from the Wikipedia URL."""
    try:
        # Decode the URL
        decoded_url = urllib.parse.unquote(url)
        
        # Extract the last part of the URL (after /wiki/)
        wiki_part = decoded_url.split('/wiki/')[-1]
        
        # Remove any special characters and replace underscores with spaces
        clean_name = wiki_part.replace('_', ' ')
        
        # If the name contains parentheses, make sure there's a space before them
        clean_name = re.sub(r'\(', ' (', clean_name)
        clean_name = re.sub(r'\s+\(', ' (', clean_name)
        
        # Remove any Wikipedia-specific suffixes
        clean_name = re.sub(r'\s*\([^)]*\)$', '', clean_name)
        
        # Convert to lowercase for comparison
        current_lower = current_name.lower()
        clean_lower = clean_name.lower()
        
        # Define fortification types that should be preserved
        fort_types = [
            'castelo', 'forte', 'fortaleza', 'muralha', 'muralhas', 'torre',
            'cidadela', 'fortificação', 'bateria', 'baluarte', 'atalaia',
            'reduto', 'praça-forte'
        ]
        
        # Check if the URL name contains a fortification type that's not in the current name
        should_use_url_name = False
        for fort_type in fort_types:
            if fort_type in clean_lower and fort_type not in current_lower:
                should_use_url_name = True
                break
        
        # Also use URL name if current name is just a part of the full name
        if current_lower in clean_lower and len(clean_name) > len(current_name):
            should_use_url_name = True
        
        if should_use_url_name:
            return clean_name
        
        return current_name
    except Exception as e:
        print(f"Error extracting name from URL {url}: {e}")
        return current_name

def get_wikidata_id_from_wikipedia(wikipedia_url):
    """Extract the Wikidata ID from a Wikipedia page."""
    try:
        response = requests.get(wikipedia_url)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Look for the Wikidata item link
        wikidata_link = soup.find("a", {"href": re.compile(r'https?://www\.wikidata\.org/wiki/Q\d+')})
        if wikidata_link:
            href = wikidata_link.get('href')
            wikidata_id = href.split('/')[-1]
            return wikidata_id
        
        # Alternative method: look for the Wikidata ID in the page source
        for script in soup.find_all("script"):
            if script.string and "wgWikibaseItemId" in script.string:
                match = re.search(r'"wgWikibaseItemId":"(Q\d+)"', script.string)
                if match:
                    return match.group(1)
        
        return None
    except Exception as e:
        print(f"Error getting Wikidata ID for {wikipedia_url}: {e}")
        return None

def get_coordinates_from_wikidata(wikidata_id):
    """Get coordinates from Wikidata using the Wikidata ID."""
    if not wikidata_id:
        return None, None
    
    try:
        # Query the Wikidata API for coordinates
        url = f"https://www.wikidata.org/w/api.php"
        params = {
            "action": "wbgetclaims",
            "format": "json",
            "entity": wikidata_id,
            "property": "P625"  # P625 is the property for coordinates
        }
        
        response = requests.get(url, params=params)
        data = response.json()
        
        # Extract coordinates from the response
        if "claims" in data and "P625" in data["claims"]:
            coordinates = data["claims"]["P625"][0]["mainsnak"]["datavalue"]["value"]
            latitude = coordinates["latitude"]
            longitude = coordinates["longitude"]
            return str(latitude), str(longitude)
        
        return None, None
    except Exception as e:
        print(f"Error getting coordinates from Wikidata for {wikidata_id}: {e}")
        return None, None

def create_google_maps_link(lat, lon):
    """Create a Google Maps link with a marker at the given coordinates."""
    if lat and lon:
        return f"https://www.google.com/maps?q={lat},{lon}"
    return ""

def is_fortification(name, url):
    """Check if a link is likely to be a fortification/castle."""
    fortification_keywords = [
        'castelo', 'forte', 'fortaleza', 'muralha', 'torre', 'cidadela',
        'fortificação', 'bateria', 'baluarte', 'atalaia', 'reduto'
    ]
    
    # Check if any of the keywords is in the name (case insensitive)
    name_lower = name.lower()
    if any(keyword in name_lower for keyword in fortification_keywords):
        return True
    
    # If not in the name, try to check the URL
    url_lower = url.lower()
    if any(keyword in url_lower for keyword in fortification_keywords):
        return True
    
    return False

def process_fortification(name, wiki_url, writer):
    """Process a single fortification and write to CSV if coordinates are found."""
    print(f"Processing: {name}")
    
    # Get proper name from URL
    proper_name = extract_proper_name_from_url(wiki_url, name)
    print(f"  Using proper name: {proper_name}")
    
    # Get Wikidata ID
    wikidata_id = get_wikidata_id_from_wikipedia(wiki_url)
    if wikidata_id:
        print(f"  Found Wikidata ID: {wikidata_id}")
        
        # Get coordinates from Wikidata
        lat, lon = get_coordinates_from_wikidata(wikidata_id)
        
        # Create Google Maps link
        google_maps_link = create_google_maps_link(lat, lon)
        
        # Write to CSV
        if lat and lon:  # Only include entries with coordinates
            with csv_lock:
                writer.writerow([proper_name, lat, lon, google_maps_link, wiki_url])
            print(f"  Found coordinates: {lat}, {lon}")
        else:
            print(f"  No coordinates found")
    else:
        print(f"  No Wikidata ID found")
    
    # Be nice to servers
    time.sleep(0.1)  # 100ms delay

def remove_duplicates(input_file, output_file):
    """Remove duplicate entries based on Wikipedia URL."""
    seen_urls = set()
    unique_rows = []
    
    with open(input_file, 'r', encoding='utf-8') as infile:
        reader = csv.reader(infile)
        header = next(reader)  # Skip header row
        
        for row in reader:
            wiki_url = row[4]  # URL is in the last column
            if wiki_url not in seen_urls:
                seen_urls.add(wiki_url)
                unique_rows.append(row)
    
    with open(output_file, 'w', newline='', encoding='utf-8') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(header)
        writer.writerows(unique_rows)

def main():
    # URL of the Wikipedia page with the list of fortifications
    url = "https://pt.wikipedia.org/wiki/Lista_de_fortificações_de_Portugal"
    
    # Send a request to the URL
    response = requests.get(url)
    
    # Parse the HTML content
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find all links in the page
    links = soup.find_all('a')
    
    # Filter links to fortification pages
    fortification_links = []
    base_url = "https://pt.wikipedia.org"
    
    for link in links:
        href = link.get('href')
        if href and href.startswith('/wiki/') and not any(x in href for x in [
            'Ficheiro:', 'Categoria:', 'Especial:', 'Ajuda:', 'Wikipédia:', 
            'Predefinição:', 'Lista_de_', 'Utilizador:', 'Discussão:'
        ]):
            # Exclude navigation links and other non-article links
            if link.text and len(link.text.strip()) > 0:
                name = link.text.strip()
                full_url = base_url + href
                
                # Only include links that are likely to be fortifications
                if is_fortification(name, full_url):
                    fortification_links.append((name, full_url))
    
    # Create a temporary CSV file
    temp_csv = 'portuguese_fortifications_temp.csv'
    final_csv = 'portuguese_fortifications.csv'
    
    with open(temp_csv, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Castle Name', 'Latitude', 'Longitude', 'Google Maps Link', 'Wikipedia Link'])
        
        # Process fortifications in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            # Submit tasks
            futures = [
                executor.submit(process_fortification, name, wiki_url, writer)
                for name, wiki_url in fortification_links
            ]
            
            # Wait for all tasks to complete
            concurrent.futures.wait(futures)
    
    # Remove duplicates and create final CSV
    remove_duplicates(temp_csv, final_csv)
    
    print(f"CSV file '{final_csv}' has been created.")

if __name__ == "__main__":
    main() 