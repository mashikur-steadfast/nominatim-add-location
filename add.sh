#!/bin/bash

# Default Configuration
NM_USER='ntim'
PROJECT_DIR='/var/www/nominatim'

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --name         Location name"
    echo "  -c, --city         City name"
    echo "  -s, --suburb       Suburb name"
    echo "  -co, --country     Country name"
    echo "  -lat, --latitude   Latitude"
    echo "  -lon, --longitude  Longitude"
    echo "  -h, --help         Show this help message"
    echo
    echo "Example:"
    echo "  $0 -n 'Zavi Soft' -c 'Dhaka' -s 'Mohammadpur' -co 'Bangladesh' -lat 23.744431306905756 -lon 90.35132875476877"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            LOCATION_NAME="$2"
            shift 2
            ;;
        -c|--city)
            CITY="$2"
            shift 2
            ;;
        -s|--suburb)
            SUBURB="$2"
            shift 2
            ;;
        -co|--country)
            COUNTRY="$2"
            shift 2
            ;;
        -lat|--latitude)
            LAT="$2"
            shift 2
            ;;
        -lon|--longitude)
            LON="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            ;;
    esac
done

# Validate required parameters
validate_params() {
    local missing_params=()
    
    [[ -z "$LOCATION_NAME" ]] && missing_params+=("location name (-n)")
    [[ -z "$CITY" ]] && missing_params+=("city (-c)")
    [[ -z "$SUBURB" ]] && missing_params+=("suburb (-s)")
    [[ -z "$COUNTRY" ]] && missing_params+=("country (-co)")
    [[ -z "$LAT" ]] && missing_params+=("latitude (-lat)")
    [[ -z "$LON" ]] && missing_params+=("longitude (-lon)")
    
    if [[ ${#missing_params[@]} -ne 0 ]]; then
        echo "Error: Missing required parameters:"
        printf '%s\n' "${missing_params[@]}"
        print_usage
    fi
    
    # Validate latitude and longitude format
    if ! [[ "$LAT" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo "Error: Invalid latitude format"
        exit 1
    fi
    if ! [[ "$LON" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
        echo "Error: Invalid longitude format"
        exit 1
    fi
}

# Generate a unique ID
UNIQUE_ID=$((RANDOM * 1))

# Create temporary OSM file
create_osm_file() {
    echo "Creating OSM file with location data..."
    cat > /tmp/custom_location.osm <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="Custom Location Script">
  <node id="${UNIQUE_ID}" lat="${LAT}" lon="${LON}" version="1">
    <tag k="name" v="${LOCATION_NAME}"/>
    <tag k="office" v="software"/>
    <tag k="addr:city" v="${CITY}"/>
    <tag k="addr:suburb" v="${SUBURB}"/>
    <tag k="addr:country" v="${COUNTRY}"/>
  </node>
</osm>
EOF
}

# Import the custom location
import_location() {
    echo "Importing custom location into Nominatim..."
    nominatim add-data --file /tmp/custom_location.osm --project-dir "${PROJECT_DIR}"
}

# Update search index
update_index() {
    echo "Reindexing Nominatim data..."
    nominatim index --project-dir "${PROJECT_DIR}" --no-boundaries
}

# Main execution
main() {
    # Validate parameters first
    validate_params
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi

    echo "Starting location addition process..."
    
    # Create OSM file
    create_osm_file
    
    # Switch to nominatim user and perform operations
    su - ${NM_USER} <<EOSSH
$(declare -f import_location)
$(declare -f update_index)
import_location
update_index
EOSSH
    
    # Cleanup
    rm -f /tmp/custom_location.osm
    
    echo "Location addition completed."
    echo "You can now search for '${LOCATION_NAME}' in your Nominatim instance."
    echo "Note: It may take a few minutes for the new location to be searchable."
}

# Run the script
main