# Collaged - Photo Collage Application

A modern Rails application for creating and sharing photo collages with drag-and-drop functionality and GUID-based access control.

## Technology Stack

**Backend:**
- Ruby 3.3.0
- Rails 7.2.2
- MongoDB with Mongoid 9.0.x ODM
- CarrierWave with RMagick 6.x for image processing
- ActiveStorage on SQLite3 for blob storage

**Frontend:**
- Hotwire (Turbo + Stimulus)
- Import maps for JavaScript
- Sass for stylesheets

**Testing:**
- RSpec 6.1
- Capybara 3.x with Selenium WebDriver
- Factory Bot for test fixtures

## Prerequisites

### Required Software

1. **Ruby 3.3.0**
   ```bash
   # Using mise (recommended)
   mise use ruby@3.3.0

   # Or using rbenv
   rbenv install 3.3.0
   rbenv local 3.3.0
   ```

2. **MongoDB 6.x or 7.x**
   ```bash
   # macOS
   brew install mongodb-community
   brew services start mongodb-community

   # Linux (Ubuntu/Debian)
   sudo apt-get install mongodb-org
   sudo systemctl start mongod

   # Verify connection
   mongosh --eval 'db.version()'
   ```

3. **ImageMagick**
   ```bash
   # macOS
   brew install imagemagick

   # Linux (Ubuntu/Debian)
   sudo apt-get install imagemagick libmagickwand-dev
   ```

## Setup

### 1. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Setup databases
rails db:migrate                    # SQLite for ActiveStorage
rails db:mongoid:create_indexes     # MongoDB indexes
```

### 2. Environment Configuration

Create `.env` file (optional):
```bash
# MongoDB configuration
MONGODB_URL=mongodb://localhost:27017/collaged_development

# Image storage
STORAGE_SERVICE=local
```

### 3. Start the Application

```bash
# Development server
rails server

# Navigate to http://localhost:3000
```

## Running Tests

```bash
# Full test suite
bundle exec rspec

# Specific test types
bundle exec rspec spec/models      # Model tests
bundle exec rspec spec/requests    # API tests
bundle exec rspec spec/system      # System/integration tests

# With coverage report
COVERAGE=true bundle exec rspec
open coverage/index.html
```

## Features

### Core Functionality

- **Collage Creation**: Create new photo collages with unique read/write URLs
- **Multi-Photo Upload**: Upload multiple images with progress tracking
- **Grid Layout**: Automatic grid-based layout with aspect ratio preservation
- **Photo Resizing**: Drag-and-drop photo resizing with 60fps performance
- **Access Control**: GUID-based read-only and read-write access URLs
- **Deletion**: User-initiated collage and photo deletion with confirmation

### Technical Features

- **Image Processing**: Automatic thumbnail and optimized variant generation
- **Duplicate Detection**: SHA1-based hash detection for duplicate uploads
- **Concurrent Editing**: Last-write-wins conflict resolution
- **Progressive Loading**: Thumbnail → grid → full resolution loading
- **Performance**: <100ms page load for structure, 60fps drag interactions

## API Documentation

See [API Contracts](/specs/001-awesome-use-the/contracts/) for OpenAPI specification.

### Example: Create Collage

```bash
curl -X POST http://localhost:3000/collages \
  -H "Content-Type: application/json" \
  -d '{"title":"My Collage"}'
```

Response:
```json
{
  "id": "uuid",
  "title": "My Collage",
  "r_guid": "read-only-uuid",
  "rw_guid": "read-write-uuid",
  "write_access": true
}
```

### Example: Upload Photo

```bash
curl -X POST http://localhost:3000/collages/[RW_GUID]/photos \
  -F "image=@path/to/photo.jpg" \
  -F "caption=Beach sunset"
```

## Docker Deployment

Build and run with Docker:

```bash
docker-compose up --build
```

This starts:
- Rails application on port 3000
- MongoDB on port 27017

See `docker-compose.yml` for configuration.

## Configuration

### MongoDB

Edit `config/mongoid.yml` for MongoDB connection settings.

### Storage

Edit `config/storage.yml` to configure image storage:
- `local`: Local disk storage (development)
- `test`: Temporary storage for tests
- `amazon`: S3 storage (production, requires credentials)

### Image Processing

RMagick settings in `config/initializers/carrierwave.rb`:
- Max file size: 10MB
- Supported formats: JPG, JPEG, GIF, PNG
- Variants: thumb (150x150), grid (800x800), full (original)

## Security

### Access Control

- Read-only URLs (r_guid): View collages, no modifications
- Read-write URLs (rw_guid): Full access including upload, resize, delete
- Server-side validation prevents unauthorized modifications
- rw_guid never exposed in read-only API responses

### File Upload

- 10MB file size limit
- Format validation (images only)
- MIME type checking
- Virus scanning recommended for production

### Dependencies

Run security audit:
```bash
gem install bundler-audit
bundle audit check
```

All vulnerabilities resolved as of 2025-09-30.

## Troubleshooting

### MongoDB Connection Issues

```bash
# Check MongoDB status
mongosh --eval 'db.serverStatus().ok'

# Restart MongoDB
brew services restart mongodb-community  # macOS
sudo systemctl restart mongod           # Linux
```

### Image Upload Failures

```bash
# Verify ImageMagick
convert --version

# Check storage directory permissions
ls -la storage/
mkdir -p storage tmp/storage
```

### Test Failures

```bash
# Reset test database
RAILS_ENV=test rails db:migrate
rails db:mongoid:drop RAILS_ENV=test
rails db:mongoid:create_indexes RAILS_ENV=test
```

## Project History

This application was modernized from Rails 3.2.14 (2013) to Rails 7.2 (2025) while preserving all original features. See [migration plan](/specs/001-awesome-use-the/plan.md) for details.

**Modernization Milestones:**
- ✅ Ruby 1.9.2 → 3.3.0
- ✅ Rails 3.2 → 7.2
- ✅ Backbone.js → Hotwire
- ✅ Mongoid 3.x → 9.0.x
- ✅ RMagick 2.x → 6.x
- ✅ Plupload → Native HTML5 uploads
- ✅ RSpec 2.14 → 6.1

## Contributing

1. Run tests: `bundle exec rspec`
2. Check style: `bundle exec rails_best_practices`
3. Update documentation as needed

## License

[Add your license here]

## Contact

[Add contact information]
