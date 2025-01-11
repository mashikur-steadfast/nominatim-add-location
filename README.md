# Nominatim Location Adder

A bash script to easily add custom locations to your Nominatim instance. This tool allows you to add places, businesses, or points of interest directly to your Nominatim database with detailed addressing information.

## Features

- Easy command-line interface with both short and long options
- Parameter validation for required fields
- Latitude and longitude format validation
- Automatic OSM file generation
- Nominatim database integration
- Automatic index updating

## Prerequisites

- Root access to the server
- Nominatim instance installed and configured
- Bash shell environment
- `nominatim` command-line tools

## Installation

1. Download the script directly:
```bash
curl -O https://raw.githubusercontent.com/mashikur-steadfast/nominatim-add-location/main/add.sh
```

2. Make it executable:
```bash
chmod +x add.sh
```

## Configuration

Default configuration variables in the script:
- `NM_USER='ntim'` - Nominatim user
- `PROJECT_DIR='/var/www/nominatim'` - Nominatim project directory

Modify these values in the script if your setup differs.

## Usage

### Basic Syntax
```bash
./add.sh [OPTIONS]
```

### Command Line Options

| Short Option | Long Option   | Description           | Required | Example Value        |
|-------------|---------------|----------------------|----------|---------------------|
| -n          | --name        | Location name        | Yes      | "Your Location Name"         |
| -c          | --city        | City name           | Yes      | "Dhaka"             |
| -s          | --suburb      | Suburb name         | Yes      | "Mohammadpur"       |
| -co         | --country     | Country name        | Yes      | "Bangladesh"        |
| -lat        | --latitude    | Latitude            | Yes      | 23.744431306905756  |
| -lon        | --longitude   | Longitude           | Yes      | 90.35132875476877   |
| -h          | --help        | Show help message   | No       | -                   |

### Example Usage

Using short options:
```bash
sudo ./add.sh -n "Your Location Name" -c "Dhaka" -s "Mohammadpur" -co "Bangladesh" -lat 23.744431306905756 -lon 90.35132875476877
```

Using long options:
```bash
sudo ./add.sh --name "Your Location Name" --city "Dhaka" --suburb "Mohammadpur" --country "Bangladesh" --latitude 23.744431306905756 --longitude 90.35132875476877
```

Show help:
```bash
./add.sh --help
```

## Process Flow

1. Validates all required parameters
2. Checks for root privileges
3. Creates a temporary OSM file with location data
4. Imports the location data into Nominatim
5. Updates the search index
6. Cleans up temporary files

## Output

The script will provide feedback at each step:
```
Starting location addition process...
Creating OSM file with location data...
Importing custom location into Nominatim...
Reindexing Nominatim data...
Location addition completed.
You can now search for '[Location Name]' in your Nominatim instance.
Note: It may take a few minutes for the new location to be searchable.
```

## Error Handling

The script includes validation for:
- Missing required parameters
- Invalid latitude/longitude formats
- Root privilege requirements

## Notes

- The location may take a few minutes to appear in search results due to indexing
- The script must be run with root privileges
- A unique random ID is generated for each location
- Temporary files are automatically cleaned up after execution

## Contributing

Feel free to submit issues and enhancement requests through GitHub's issue tracker.

## License

MIT License - feel free to use and modify for your needs.

## Author

Mashikur Rahman (mashikur.steadfast@gmail.com)

## Version History

- 1.0.0 (2025-01-12)
  - Initial release
  - Basic location addition functionality
  - Parameter validation
  - Documentation