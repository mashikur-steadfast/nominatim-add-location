# GeoLocation Create API Documentation

### Step 1: Install the API Script

To install the **GeoLocation Create API** script on your server:

1. **Download the script**:

```bash
curl -O https://raw.githubusercontent.com/mashikur-steadfast/nominatim-add-location/refs/heads/main/api.sh
```

2. **Set executable permissions**:

```bash
chmod +x api.sh
```

3. **Run the script**:

```bash
bash api.sh
```

This will:

- Start Apache on port `9999`.
- Set up a new virtual host for the **GeoLocation Create API**.
- Ensure the correct PHP version is used.
- Embed the API handling code in `/var/www/api/index.php`.

### Step 2: Set the API Key

1. Open the `/var/www/api/index.php` file and replace the placeholder API key `XXXX` with your actual API key.

```php
define('API_KEY', 'YOUR_API_KEY');
```

### Step 3: Authentication

To authenticate your API requests, include the `X-API-Key` header with your valid API key.

### Step 4: Postman Collection

For an enhanced experience with the **GeoLocation Create API**, you can download and import the Postman collection to quickly test the API.

- [Download the Postman Collection](https://raw.githubusercontent.com/mashikur-steadfast/nominatim-add-location/refs/heads/main/postman_collection.json)

### Step 5: Example Request

Here is an example of how to send a `POST` request to the API using `curl`:

```bash
curl -X POST http://localhost:9999 \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Location Name",
    "city": "City Name",
    "suburb": "Suburb Name",
    "country": "Country Name",
    "latitude": 40.7128,
    "longitude": -74.0060
}'
```

### Example Response

**Success:**

```json
{
  "success": true,
  "message": "Location added successfully",
  "output": ["Script output"]
}
```

**Error (Invalid API Key):**

```json
{
  "error": "Invalid API key"
}
```

**Error (Missing Fields):**

```json
{
  "error": "Missing required fields: name, city, suburb, country, latitude, longitude"
}
```

---

The **GeoLocation Create API** is now ready to use after completing the installation and configuration steps!