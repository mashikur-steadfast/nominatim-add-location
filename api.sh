#!/bin/bash

# Ensure Apache is running
echo "Starting Apache web server..."
systemctl start apache2
systemctl enable apache2

# Check if port 9999 is already configured
if ! grep -q "Listen 9999" /etc/apache2/ports.conf; then
  # Configure Apache to listen on port 9999
  echo "Configuring Apache to listen on port 9999..."
  echo "Listen 9999" >> /etc/apache2/ports.conf
else
  echo "Port 9999 is already configured."
fi

# Create a new virtual host configuration for the web server
echo "Setting up Apache virtual host..."
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:9999>
    DocumentRoot /var/www/api
    DirectoryIndex index.php

    <Directory /var/www/api>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable the site and restart Apache to apply changes
echo "Enabling site configuration and restarting Apache..."
a2ensite 000-default.conf
systemctl restart apache2

# Ensure PHP 8.3 is the active PHP version
echo "Setting PHP 8.3 as the active version..."
update-alternatives --set php /usr/bin/php8.3
systemctl restart apache2

# Create the /var/www/api directory if it doesn't exist
echo "Creating /var/www/api directory..."
mkdir -p /var/www/api

# Embed the PHP code directly into the script for /var/www/api/index.php
echo "Creating the index.php with embedded PHP code..."
cat <<'EOF' > /var/www/api/index.php
<?php
header('Content-Type: application/json');

// Configuration
define('GITHUB_RAW_URL', 'https://raw.githubusercontent.com/mashikur-steadfast/nominatim-add-location/refs/heads/main/add.sh');
define('SCRIPT_PATH', '/tmp/add.sh');
define('API_KEY', 'XXXX');

// Validate API key
function validateApiKey($headers) {
    if (!isset($headers['X-API-Key']) || $headers['X-API-Key'] !== API_KEY) {
        http_response_code(401);
        return ['error' => 'Invalid API key'];
    }
    return true;
}

// Validate input parameters
function validateInput($data) {
    $required = ['name', 'city', 'suburb', 'country', 'latitude', 'longitude'];
    $missing = [];
    
    foreach ($required as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            $missing[] = $field;
        }
    }
    
    if (!empty($missing)) {
        return ['error' => 'Missing required fields: ' . implode(', ', $missing)];
    }
    
    // Validate latitude and longitude format
    if (!is_numeric($data['latitude']) || !is_numeric($data['longitude'])) {
        return ['error' => 'Invalid latitude or longitude format'];
    }
    
    // Validate latitude range
    if ($data['latitude'] < -90 || $data['latitude'] > 90) {
        return ['error' => 'Latitude must be between -90 and 90'];
    }
    
    // Validate longitude range
    if ($data['longitude'] < -180 || $data['longitude'] > 180) {
        return ['error' => 'Longitude must be between -180 and 180'];
    }
    
    return true;
}

// Download and verify script
function downloadScript() {
    $script = file_get_contents(GITHUB_RAW_URL);
    if ($script === false) {
        return ['error' => 'Failed to download script from GitHub'];
    }
    
    // Save script to temporary location
    if (file_put_contents(SCRIPT_PATH, $script) === false) {
        return ['error' => 'Failed to save script'];
    }
    
    // Make script executable
    if (!chmod(SCRIPT_PATH, 0755)) {
        return ['error' => 'Failed to make script executable'];
    }
    
    return true;
}

// Execute script with parameters
function executeScript($data) {
    $command = sprintf(
        'sudo %s -n "%s" -c "%s" -s "%s" -co "%s" -lat %s -lon %s 2>&1',
        SCRIPT_PATH,
        escapeshellarg($data['name']),
        escapeshellarg($data['city']),
        escapeshellarg($data['suburb']),
        escapeshellarg($data['country']),
        escapeshellarg($data['latitude']),
        escapeshellarg($data['longitude'])
    );
    
    exec($command, $output, $return_code);
    
    // Clean up
    unlink(SCRIPT_PATH);
    
    if ($return_code !== 0) {
        return [
            'error' => 'Script execution failed',
            'details' => implode("\n", $output)
        ];
    }
    
    return [
        'success' => true,
        'message' => 'Location added successfully',
        'output' => $output
    ];
}

// Main API logic
function handleRequest() {
    // Only accept POST requests
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        return ['error' => 'Method not allowed'];
    }
    
    // Get headers
    $headers = getallheaders();
    
    // Validate API key
    $keyValidation = validateApiKey($headers);
    if (is_array($keyValidation)) {
        return $keyValidation;
    }
    
    // Get and decode JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        return ['error' => 'Invalid JSON data'];
    }
    
    // Validate input
    $validation = validateInput($input);
    if (is_array($validation)) {
        http_response_code(400);
        return $validation;
    }
    
    // Download and verify script
    $download = downloadScript();
    if (is_array($download)) {
        http_response_code(500);
        return $download;
    }
    
    // Execute script
    return executeScript($input);
}

// Execute and output response
$response = handleRequest();
echo json_encode($response, JSON_PRETTY_PRINT);
?>
EOF

# Set appropriate permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/api

# Check if the line already exists to avoid duplicates
if ! grep -q "www-data ALL=(ALL) NOPASSWD: /tmp/add.sh" /etc/sudoers; then
    echo "www-data ALL=(ALL) NOPASSWD: /tmp/add.sh" | sudo tee -a /etc/sudoers > /dev/null
    echo "Line added successfully to /etc/sudoers"
fi

# Finished
echo "Web server setup complete. You can access it at http://localhost:9999"
