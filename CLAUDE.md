# collaged Development Guidelines

Rails 7.2 photo collage application with MongoDB. Last updated: 2025-10-01

## Active Technologies
- Ruby 3.3.0, JavaScript (ES6+) + Rails 7.2.2, Hotwire (Turbo 8.x, Stimulus 3.x), Mongoid 9.0.x, RMagick 6.x, CarrierWave (001-awesome-use-the)
- MongoDB (collages, photos), SQLite3 (ActiveStorage blobs), File system (image uploads via CarrierWave) (001-awesome-use-the)
- Ruby 3.3.0, JavaScript ES6+ (Rails 7.2.2 application) + Hotwire (Turbo 8.x, Stimulus 3.x), Mongoid 9.0.x, RMagick 6.x, CarrierWave (001-awesome-use-the)
- MongoDB (collages, photos with ordinal field), SQLite3 (ActiveStorage blobs), File system (image uploads) (001-awesome-use-the)

**Backend:**
- Ruby 3.3.0 (managed with mise)
- Rails 7.2.2
- MongoDB with Mongoid 9.0.x
- CarrierWave + RMagick 6.x for image processing
- ActiveStorage on SQLite3 for blob storage

**Frontend:**
- Hotwire (Turbo + Stimulus)
- Import maps
- Sass

**Testing:**
- RSpec 6.1 with Capybara 3.x

## Project Structure
```
app/
  controllers/     # Rails controllers (collages, photos)
  models/          # Mongoid models (Collage, Photo)
  views/           # ERB templates
  javascript/
    controllers/   # Stimulus controllers
      grid_controller.js         # Grid layout and rendering
      photo_resize_controller.js # Photo edge-dragging resize
      photo_reorder_controller.js # Drag-and-drop reordering (NEW)
      upload_controller.js       # File upload handling
  assets/          # Stylesheets, images
config/
  mongoid.yml      # MongoDB configuration
  database.yml     # SQLite (ActiveStorage only)
  storage.yml      # Image storage configuration
  initializers/
    assets.rb      # Sprockets asset precompilation config
spec/
  models/          # Model specs
  requests/        # API specs
  system/          # System/integration specs
specs/001-awesome-use-the/  # Feature specification and plan
```

## Commands

```bash
# Setup
mise use ruby@3.3.0              # Set Ruby version
bundle install                    # Install gems
rails db:migrate                  # SQLite migrations
rails db:mongoid:create_indexes   # MongoDB indexes

# Development
rails server                      # Start dev server
rails console                     # Open Rails console

# Testing
bundle exec rspec                 # Run all tests
bundle exec rspec spec/models     # Model tests only
COVERAGE=true bundle exec rspec   # With coverage

# Security
bundle audit check                # Check for vulnerabilities

# Database
rails db:mongoid:drop             # Drop MongoDB collections
rails db:mongoid:create_indexes   # Recreate indexes
mongosh collaged_development      # MongoDB shell
```

## Code Style

- Follow Rails conventions
- Use Rubocop for linting: `bundle exec rubocop`
- Model validations required before save
- Controller actions should be RESTful
- Use strong parameters for mass assignment protection

## MongoDB Specifics

- Models use `include Mongoid::Document`
- Embedded documents: Photos embedded in Collages
- Indexes defined in models with `index` directive
- GUIDs for access control (r_guid, rw_guid)
- Use `.find_by_guid` for GUID lookups

## Image Processing

- Max file size: 10MB
- Formats: JPG, JPEG, GIF, PNG only
- CarrierWave uploaders in `app/uploaders/`
- Automatic variant generation (thumb, grid, full)
- SHA1 hash for duplicate detection

## Photo Interactions

### Drag-and-Drop Reordering
- **Controller**: `app/javascript/controllers/photo_reorder_controller.js`
- **API**: `PATCH /collages/:collage_id/photos/:photo_id` with `{ photo: { ordinal: N } }`
- **Implementation**: HTML5 Drag and Drop API with Stimulus
- **Visual Feedback**: Grab cursor, opacity during drag, blue dashed border on drop target
- **Performance**: requestAnimationFrame throttling for 60fps
- **Grid Integration**: Dispatches `reorder:photoMoved` event for automatic grid reflow
- **Access Control**: Only enabled for write access (rw_guid)

### Photo Resizing
- **Controller**: `app/javascript/controllers/photo_resize_controller.js`
- **Interaction**: Drag photo edges (within 20px) to resize
- **Aspect Ratios**: Maintains original aspect ratio or allows custom ratios
- **Grid Integration**: Updates photo dimensions and triggers grid reflow

## Testing Guidelines

- Factory Bot for test data
- Database Cleaner for test isolation
- System tests use Selenium WebDriver
- Mock external services in tests
- Maintain >90% code coverage

## Recent Changes
- **2025-10-01**: Implemented photo drag-and-drop reordering (001-awesome-use-the)
  - Added `photo_reorder_controller.js` with HTML5 Drag and Drop API
  - Integrated with grid controller for automatic reflow
  - Updated `config/initializers/assets.rb` for asset precompilation
  - Added drag-and-drop CSS styles (grab cursor, visual feedback)
  - Full TDD approach with system and integration tests
  - Maintains 60fps performance target with requestAnimationFrame

- **2025-09-30**: Completed Rails 7.2 modernization
  - Upgraded from Rails 3.2.14 to 7.2.2
  - Ruby 1.9.2 → 3.3.0
  - Backbone.js → Hotwire
  - Mongoid 3.x → 9.0.x
  - RMagick 4.x → 6.x (security fix)
  - All 53 functional requirements preserved

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
