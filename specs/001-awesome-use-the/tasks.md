# Tasks: Collaged Full Dependency Modernization

**Feature**: Modernize Rails 3.2.14 + Backbone.js to Rails 7.2 + Hotwire
**Input**: Design documents from `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/collaged-api.yaml, quickstart.md

## Overview

This document contains 62 dependency-ordered tasks for incrementally modernizing the Collaged application from 2013-era technology stack to modern Rails 7.2 + Hotwire, while preserving all 53 functional requirements.

**Constitutional Principles Applied**:
- Feature Preservation (NON-NEGOTIABLE)
- Incremental Modernization
- Test Coverage Before Changes
- Technology Stack Modernization
- Data Integrity
- Performance Preservation
- Documentation and Knowledge Transfer

## Path Conventions

Rails monolith structure at repository root:
- Models: `app/models/`
- Controllers: `app/controllers/`
- Views: `app/views/`
- JavaScript: `app/javascript/` (Rails 7.x)
- Tests: `spec/` (RSpec), `spec/system/` (system tests)
- Config: `config/`

## Phase P0: Characterization (BEFORE ANY CHANGES)

**CRITICAL**: These tasks must complete FIRST to establish behavioral baseline.

- [x] **T001** Document current test suite status in `docs/characterization/test-baseline.md`
  - Run existing RSpec + Cucumber tests
  - Document passing, failing, and skipped tests
  - Create coverage report (SimpleCov)
  - **Acceptance**: Baseline documented with test counts and coverage percentage
  - **Test**: `bundle exec rspec && bundle exec cucumber`
  - **Rollback**: Delete docs/characterization/ directory

- [x] **T002** [P] Create characterization tests for Collage CRUD in `spec/models/collage_spec.rb`
  - Test current GUID generation behavior (UUIDTools)
  - Test find_by_guid with r_guid and rw_guid
  - Test write_access flag behavior
  - Test title validation
  - **Acceptance**: Tests pass on current codebase (Rails 3.2)
  - **Test**: `bundle exec rspec spec/models/collage_spec.rb`
  - **Rollback**: `git checkout spec/models/collage_spec.rb`

- [x] **T003** [P] Create characterization tests for Photo model in `spec/models/photo_spec.rb`
  - Test grid dimension calculation (prime factorization)
  - Test aspect ratio preservation
  - Test image_hash generation (SHA1)
  - Test ordinal sorting
  - Test size = width × height constraint
  - **Acceptance**: Tests document current behavior
  - **Test**: `bundle exec rspec spec/models/photo_spec.rb`
  - **Rollback**: `git checkout spec/models/photo_spec.rb`

- [x] **T004** [P] Document legacy JavaScript behavior in `docs/characterization/frontend-baseline.md`
  - Backbone.js routes and models
  - jQuery event handlers
  - Plupload upload flow (document runtime selection: HTML5 vs Flash/Silverlight fallbacks if present)
  - Drag-and-drop resize interactions
  - Multi-file selection behavior
  - Progress tracking mechanism
  - **Acceptance**: All JS interactions documented with runtime capabilities
  - **Test**: Manual review + inspect Plupload initialization code
  - **Rollback**: Delete docs/characterization/frontend-baseline.md

- [x] **T005** [P] Export production MongoDB schema to `docs/characterization/mongodb-schema.json`
  - Run `mongodump --db collaged_production`
  - Document indexes, field types, sample data
  - Verify no orphaned data
  - **Acceptance**: Schema export complete with validation
  - **Test**: `mongo collaged_development --eval 'db.collages.findOne()'`
  - **Rollback**: No rollback needed (read-only)

- [x] **T006** [P] Create performance baseline in `docs/characterization/performance-baseline.md`
  - Measure page load times (Lighthouse)
  - Measure drag-and-drop FPS
  - Measure image upload duration
  - Document memory usage
  - **Acceptance**: Metrics documented for comparison
  - **Test**: `lighthouse http://localhost:3000/collages/[GUID]`
  - **Rollback**: Delete docs/characterization/performance-baseline.md

- [x] **T007** Tag repository checkpoint
  - Create git tag: `characterization-complete`
  - **Acceptance**: Tag created, all P0 tasks complete
  - **Test**: `git tag -l | grep characterization-complete`
  - **Rollback**: `git tag -d characterization-complete`

---

## Phase P1: Foundation Upgrade (Ruby + Rails + Mongoid)

**CRITICAL PATH**: Sequential upgrades with test validation at each step.

- [x] **T008** Upgrade Ruby 1.9.2 → 2.7.8
  - Update `.ruby-version`
  - Update Gemfile `ruby` directive
  - Run `bundle install`
  - Fix Ruby 2.7 deprecation warnings
  - **Acceptance**: Test suite passes on Ruby 2.7
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout .ruby-version Gemfile Gemfile.lock`

- [x] **T009** Upgrade Rails 3.2.14 → 4.2.11.3 (EOL but necessary step)
  - Update `Gemfile`: `gem 'rails', '~> 4.2.11'`
  - Run `bundle update rails`
  - Update `config/application.rb` for Rails 4.2
  - Migrate `attr_accessible` → strong_parameters in controllers
  - Update routes syntax
  - **Acceptance**: `rails server` starts, test suite passes
  - **Test**: `bundle exec rspec && rails server`
  - **Rollback**: `git checkout Gemfile* config/ app/controllers/`

- [x] **T010** Update Rails 4.2 deprecation warnings
  - Fix ActiveRecord relation warnings
  - Update test helper configurations
  - Remove deprecated `before_filter` → `before_action`
  - **Acceptance**: No Rails deprecation warnings in test output
  - **Test**: `bundle exec rspec 2>&1 | grep DEPRECATION`
  - **Rollback**: `git checkout app/`

- [x] **T011** Tag checkpoint: `rails-4.2-stable`
  - **Acceptance**: Tag created, tests passing
  - **Test**: `git tag -l | grep rails-4.2`
  - **Rollback**: `git tag -d rails-4.2-stable`

- [x] **T012** Upgrade Rails 4.2 → 5.2.8.1
  - Update `Gemfile`: `gem 'rails', '~> 5.2.8'`
  - Run `rails app:update`
  - Update `config/application.rb` for Rails 5.2
  - Migrate asset pipeline to Webpacker
  - Update secrets.yml → credentials
  - **Acceptance**: Test suite passes on Rails 5.2
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile* config/`

- [x] **T013** Upgrade Rails 5.2 → 6.1.7.6
  - Update `Gemfile`: `gem 'rails', '~> 6.1.7'`
  - Run `rails app:update`
  - Add Zeitwerk autoloading
  - Update ActiveRecord schema format
  - **Acceptance**: Test suite passes on Rails 6.1
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile* config/`

- [x] **T014** Tag checkpoint: `rails-6.1-stable`
  - **Acceptance**: Tag created, tests passing
  - **Test**: `git tag -l | grep rails-6.1`
  - **Rollback**: `git tag -d rails-6.1-stable`

- [x] **T015** Upgrade Rails 6.1 → 7.2.x
  - Update `Gemfile`: `gem 'rails', '~> 7.2'`
  - Run `rails app:update`
  - Migrate Webpacker → Propshaft/import maps
  - Update ActiveStorage configuration
  - **Acceptance**: Test suite passes on Rails 7.2
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile* config/`

- [x] **T016** Upgrade Ruby 2.7 → 3.3.x
  - Update `.ruby-version` to `3.3.0`
  - Update Gemfile `ruby` directive
  - Fix Ruby 3.x keyword argument warnings
  - **Acceptance**: Test suite passes on Ruby 3.3 + Rails 7.2
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout .ruby-version Gemfile`

- [x] **T017** Upgrade Mongoid 3.1.4 → 9.0.x
  - Update `Gemfile`: `gem 'mongoid', '~> 9.0'`
  - Run `rails g mongoid:config` and merge with existing config
  - Update model syntax: `order: [[:ordinal, :asc]]` → `order: :ordinal.asc`
  - Test query compatibility
  - **Acceptance**: MongoDB queries work correctly
  - **Test**: `bundle exec rspec spec/models/`
  - **Rollback**: `git checkout Gemfile* config/mongoid.yml app/models/`

- [x] **T018** Create MongoDB indexes for modern Mongoid
  - Run `rails db:mongoid:create_indexes`
  - Verify `r_guid`, `rw_guid` unique indexes
  - Verify `photos.ordinal`, `photos.image_hash` indexes
  - **Acceptance**: All indexes present
  - **Test**: `mongo collaged_development --eval 'db.collages.getIndexes()'`
  - **Rollback**: `mongo collaged_development --eval 'db.collages.dropIndexes()'`

- [x] **T019** Tag checkpoint: `rails-7.2-mongoid-9-stable`
  - **Acceptance**: Tag created, full test suite passes
  - **Test**: `bundle exec rspec && bundle exec rails server`
  - **Rollback**: `git tag -d rails-7.2-mongoid-9-stable`

---

## Phase P2: Backend Modernization (Image Processing + API)

**Prerequisites**: Phase P1 complete (Rails 7.2 + Mongoid 9.x)

- [ ] **T020** Install ActiveStorage and libvips
  - Run `rails active_storage:install`
  - Run migrations
  - Install libvips: `brew install vips` (macOS) or `apt-get install libvips-tools` (Linux)
  - Update `Gemfile`: `gem 'image_processing', '~> 1.12'`
  - **Acceptance**: ActiveStorage tables created, libvips >= 8.10 installed with JPEG/PNG/GIF support
  - **Test**: `rails db:migrate && vips --version | grep -E '8\.(1[0-9]|[2-9][0-9])|^[9-9]' && vips list | grep -E 'jpeg|png|gif'`
  - **Rollback**: `rails db:rollback && brew uninstall vips` (macOS) or `apt-get remove libvips-tools` (Linux)

- [ ] **T021** Update Photo model for ActiveStorage in `app/models/photo.rb`
  - Add `has_one_attached :image` with variants (thumb, grid, full)
  - Add dual-read `image_url` method (ActiveStorage or CarrierWave fallback)
  - Keep CarrierWave uploader temporarily
  - **Acceptance**: Photo model supports both upload systems
  - **Test**: `bundle exec rspec spec/models/photo_spec.rb`
  - **Rollback**: `git checkout app/models/photo.rb`

- [ ] **T022** Create image migration rake task in `lib/tasks/collaged.rake`
  - Implement `rails collaged:migrate_images` task
  - Migrate CarrierWave → ActiveStorage with hash verification
  - Log migration progress
  - Skip already-migrated photos
  - **Acceptance**: Rake task runs without errors
  - **Test**: `rails collaged:migrate_images RAILS_ENV=test`
  - **Rollback**: Delete `lib/tasks/collaged.rake`

- [ ] **T023** Run image migration on development data
  - Execute `rails collaged:migrate_images`
  - Verify all photos have ActiveStorage blobs
  - Check variant generation
  - **Acceptance**: 100% of photos migrated
  - **Test**: `Photo.where(:image.exists => false).count # Should be 0`
  - **Rollback**: `rails db:mongoid:drop && rails db:mongoid:create_indexes && rails db:seed`

- [ ] **T024** Replace UUIDTools with SecureRandom in `app/models/collage.rb`
  - Update `initialize_guids` method
  - Replace `UUIDTools::UUID.random_create.to_s` → `SecureRandom.uuid`
  - Remove `uuidtools` gem from Gemfile
  - **Acceptance**: New collages generate valid UUIDs
  - **Test**: `bundle exec rspec spec/models/collage_spec.rb`
  - **Rollback**: `git checkout app/models/collage.rb Gemfile`

- [ ] **T025** Update Integer#factors for Ruby 3.3 in `config/initializers/integer_extensions.rb`
  - Move from `app/models/photo.rb` to initializer
  - Ensure compatibility with modern Ruby
  - **Acceptance**: Grid calculations work correctly
  - **Test**: `bundle exec rspec spec/models/photo_spec.rb`
  - **Rollback**: `rm config/initializers/integer_extensions.rb`

- [ ] **T026** [P] Write contract test for POST /collages in `spec/requests/collages_create_spec.rb`
  - Test HTTP 201 with valid title
  - Test HTTP 422 with blank title
  - Validate response schema matches OpenAPI spec
  - Test GUID generation
  - **Acceptance**: Test fails (endpoint not updated yet)
  - **Test**: `bundle exec rspec spec/requests/collages_create_spec.rb`
  - **Rollback**: `rm spec/requests/collages_create_spec.rb`

- [ ] **T027** [P] Write contract test for GET /collages/{guid} in `spec/requests/collages_show_spec.rb`
  - Test HTTP 200 with valid GUID
  - Test HTTP 404 with invalid GUID
  - Validate read-only vs read-write response schemas
  - Test `write_access` flag behavior
  - **Acceptance**: Test fails (endpoint not updated yet)
  - **Test**: `bundle exec rspec spec/requests/collages_show_spec.rb`
  - **Rollback**: `rm spec/requests/collages_show_spec.rb`

- [ ] **T028** [P] Write contract test for DELETE /collages/{guid} in `spec/requests/collages_destroy_spec.rb`
  - Test HTTP 204 with write GUID
  - Test HTTP 403 with read-only GUID
  - Test HTTP 404 with invalid GUID
  - **Acceptance**: Test fails (endpoint not updated yet)
  - **Test**: `bundle exec rspec spec/requests/collages_destroy_spec.rb`
  - **Rollback**: `rm spec/requests/collages_destroy_spec.rb`

- [ ] **T029** [P] Write contract test for POST /collages/{guid}/photos in `spec/requests/photos_create_spec.rb`
  - Test HTTP 201 with valid image
  - Test HTTP 403 with read-only GUID
  - Test HTTP 413 with >10MB file
  - Test HTTP 422 with invalid format
  - Test HTTP 409 for duplicate detection
  - **Acceptance**: Test fails (endpoint not updated yet)
  - **Test**: `bundle exec rspec spec/requests/photos_create_spec.rb`
  - **Rollback**: `rm spec/requests/photos_create_spec.rb`

- [ ] **T030** [P] Write contract test for PATCH /collages/{guid}/photos/{id} in `spec/requests/photos_update_spec.rb`
  - Test HTTP 200 with valid dimensions
  - Test HTTP 403 with read-only GUID
  - Test HTTP 422 with invalid dimensions (size != width × height)
  - **Acceptance**: Test fails (endpoint not updated yet)
  - **Test**: `bundle exec rspec spec/requests/photos_update_spec.rb`
  - **Rollback**: `rm spec/requests/photos_update_spec.rb`

- [ ] **T031** Update CollagesController for Rails 7.2 JSON API in `app/controllers/collages_controller.rb`
  - Implement strong_parameters
  - Update create/show/update/destroy actions
  - Handle write_access logic in responses
  - Return OpenAPI-compliant JSON
  - **Acceptance**: Contract tests T026-T028 pass
  - **Test**: `bundle exec rspec spec/requests/collages_*.rb`
  - **Rollback**: `git checkout app/controllers/collages_controller.rb`

- [ ] **T032** Update PhotosController for Rails 7.2 JSON API in `app/controllers/photos_controller.rb`
  - Implement strong_parameters
  - Update create/update/destroy actions
  - Handle ActiveStorage uploads
  - Implement duplicate detection (HTTP 409)
  - **Acceptance**: Contract tests T029-T030 pass
  - **Test**: `bundle exec rspec spec/requests/photos_*.rb`
  - **Rollback**: `git checkout app/controllers/photos_controller.rb`

- [ ] **T033** Remove CarrierWave dependency
  - Remove `mount_uploader` from Photo model
  - Remove `app/uploaders/` directory
  - Remove CarrierWave gem from Gemfile
  - Update image_url method (ActiveStorage only)
  - **Acceptance**: Tests pass without CarrierWave
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile app/models/photo.rb app/uploaders/`

- [ ] **T034** Tag checkpoint: `backend-modernized`
  - **Acceptance**: All backend tests pass
  - **Test**: `bundle exec rspec spec/models/ spec/requests/`
  - **Rollback**: `git tag -d backend-modernized`

---

## Phase P3: Frontend Modernization (Hotwire)

**Prerequisites**: Phase P2 complete (Rails 7.2 backend stable)

- [ ] **T035** Install Hotwire dependencies
  - Update `Gemfile`: `gem 'turbo-rails'`, `gem 'stimulus-rails'`
  - Run `bundle install`
  - Run `rails turbo:install stimulus:install`
  - Configure Propshaft or import maps
  - **Acceptance**: Hotwire assets available
  - **Test**: `rails assets:precompile`
  - **Rollback**: `git checkout Gemfile* config/ app/javascript/`

- [ ] **T036** Create Stimulus controller for collage creation in `app/javascript/controllers/collage_form_controller.js`
  - Handle form submission via Turbo Frame
  - Display validation errors inline
  - Redirect to collage show page on success
  - **Acceptance**: Collage creation works without Backbone
  - **Test**: Manual browser test + system test
  - **Rollback**: `rm app/javascript/controllers/collage_form_controller.js`

- [ ] **T037** Create Stimulus controller for photo upload in `app/javascript/controllers/upload_controller.js`
  - Implement ActiveStorage Direct Upload
  - Handle multi-file selection (File API)
  - Display progress bars with percentage
  - Show duplicate warnings (store image_hash list in Rails session, show alert on first duplicate per session, silent thereafter)
  - Support drag-and-drop file upload
  - Replace Plupload functionality completely
  - **Acceptance**: Photo upload works with progress tracking, duplicate detection matches FR-017 to FR-019
  - **Test**: Manual browser test (upload same file twice) + system test spec/system/photo_upload_spec.rb
  - **Rollback**: `rm app/javascript/controllers/upload_controller.js`

- [ ] **T038** Create Stimulus controller for drag-and-drop resize in `app/javascript/controllers/photo_resize_controller.js`
  - Detect cursor within 10px of edge for all four sides (left: X < photo.x + 10, right: X > photo.x + width - 10, top: Y < photo.y + 10, bottom: Y > photo.y + height - 10)
  - Handle drag events (mousedown, mousemove, mouseup) with appropriate cursor styles
  - Update grid dimensions (size, width, height) maintaining size = width × height constraint
  - Trigger grid re-flow via grid_controller
  - Achieve 60fps performance (validate <16.67ms per frame using Chrome DevTools Performance panel)
  - **Acceptance**: Photo resizing works smoothly on all four edges, meets FR-034 to FR-040
  - **Test**: Manual browser test with Chrome DevTools Performance (record timeline, verify no dropped frames)
  - **Rollback**: `rm app/javascript/controllers/photo_resize_controller.js`

- [ ] **T039** Create Stimulus controller for grid layout in `app/javascript/controllers/grid_controller.js`
  - Calculate photo positions (left-to-right, top-to-bottom)
  - Handle grid re-flow on resize/delete
  - Snap to cell boundaries
  - **Acceptance**: Grid layout matches legacy behavior
  - **Test**: Manual browser test + visual regression
  - **Rollback**: `rm app/javascript/controllers/grid_controller.js`

- [ ] **T040** Update views to use Turbo Frames in `app/views/collages/`
  - Wrap collage form in `<turbo-frame>`
  - Add Stimulus `data-controller` attributes
  - Remove Backbone templates
  - **Acceptance**: Views render correctly with Hotwire
  - **Test**: `rails server` + manual verification
  - **Rollback**: `git checkout app/views/`

- [ ] **T041** Remove Backbone.js and dependencies
  - Delete `app/assets/javascripts/models/`
  - Delete `app/assets/javascripts/views/`
  - Delete `app/assets/javascripts/routers/`
  - Remove Backbone, Underscore, jQuery from asset pipeline
  - **Acceptance**: Application works without Backbone
  - **Test**: `rails server` + full manual QA
  - **Rollback**: `git checkout app/assets/javascripts/`

- [ ] **T042** Replace jQuery with native JavaScript where possible
  - Update event handlers to use `addEventListener`
  - Replace `$.ajax` with `fetch` or Turbo
  - Remove jQuery dependency if unused
  - **Acceptance**: All JS interactions work
  - **Test**: Manual browser test
  - **Rollback**: `git checkout app/javascript/`

- [ ] **T043** Replace Underscore.js with ES6+ methods
  - Replace `_.each` → `Array.forEach`
  - Replace `_.map` → `Array.map`
  - Replace `_.filter` → `Array.filter`
  - Remove Underscore dependency
  - **Acceptance**: All JS functions work
  - **Test**: Manual browser test
  - **Rollback**: `git checkout app/javascript/`

- [ ] **T044** Tag checkpoint: `frontend-modernized`
  - **Acceptance**: Full application works with Hotwire
  - **Test**: `rails server` + quickstart.md scenarios
  - **Rollback**: `git tag -d frontend-modernized`

---

## Phase P4: Testing Infrastructure Modernization

**Prerequisites**: Phase P3 complete (can run in parallel after P2)

- [ ] **T045** [P] Upgrade RSpec 2.14 → 6.1
  - Update `Gemfile`: `gem 'rspec-rails', '~> 6.1'`
  - Run `bundle update rspec-rails`
  - Update spec_helper.rb and rails_helper.rb
  - Fix deprecated RSpec syntax
  - **Acceptance**: Existing tests pass on RSpec 6.1
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile* spec/spec_helper.rb`

- [ ] **T046** [P] Upgrade Capybara 0.4 → 3.x
  - Update `Gemfile`: `gem 'capybara', '~> 3.0'`
  - Run `bundle update capybara`
  - Configure Selenium or Cuprite driver
  - Update Capybara DSL usage
  - **Acceptance**: System tests run with modern driver
  - **Test**: `bundle exec rspec spec/system/`
  - **Rollback**: `git checkout Gemfile* spec/support/`

- [ ] **T047** [P] Remove deprecated test gems
  - Remove Akephalos (obsolete headless browser)
  - Remove Spork (test server)
  - Remove Turn (test formatter)
  - Update Gemfile
  - **Acceptance**: Test suite runs without removed gems
  - **Test**: `bundle exec rspec`
  - **Rollback**: `git checkout Gemfile*`

- [ ] **T048** [P] Migrate Cucumber scenarios to RSpec system tests
  - Convert `features/collage_creation.feature` → `spec/system/collage_creation_spec.rb`
  - Convert `features/photo_upload.feature` → `spec/system/photo_upload_spec.rb`
  - Convert `features/photo_resize.feature` → `spec/system/photo_resize_spec.rb`
  - Remove Cucumber dependency
  - **Acceptance**: All scenarios covered by system tests
  - **Test**: `bundle exec rspec spec/system/`
  - **Rollback**: `rm -rf spec/system/ && git checkout features/`

- [ ] **T049** [P] Add performance benchmarks in `spec/performance/`
  - Test page load <100ms (structure only, measure Time to Interactive via Lighthouse)
  - Test drag-and-drop 60fps (use Chrome Performance API: performance.mark/measure, validate <16.67ms frame budget)
  - Test image upload duration (10MB file baseline)
  - Generate HTML report with metrics vs. baseline (from T006)
  - **Acceptance**: Performance tests run and report metrics with pass/fail thresholds
  - **Test**: `bundle exec rspec spec/performance/` produces report comparing to docs/characterization/performance-baseline.md
  - **Rollback**: `rm -rf spec/performance/`

- [ ] **T050** [P] Set up SimpleCov for coverage reporting
  - Add SimpleCov to spec_helper.rb
  - Configure minimum coverage thresholds (>90%)
  - Generate HTML report
  - **Acceptance**: Coverage report generated
  - **Test**: `COVERAGE=true bundle exec rspec && open coverage/index.html`
  - **Rollback**: `git checkout spec/spec_helper.rb`

- [ ] **T051** [P] Add committee gem for OpenAPI contract validation
  - Update `Gemfile`: `gem 'committee-rails'`
  - Configure committee middleware
  - Run contract validation tests
  - **Acceptance**: All API responses match OpenAPI schema
  - **Test**: `bundle exec rspec spec/contracts/`
  - **Rollback**: `git checkout Gemfile* config/`

- [ ] **T052** Tag checkpoint: `testing-modernized`
  - **Acceptance**: Modern test suite passes >90% coverage
  - **Test**: `COVERAGE=true bundle exec rspec`
  - **Rollback**: `git tag -d testing-modernized`

---

## Phase P5: Validation & Polish

**Prerequisites**: Phases P1-P4 complete

- [ ] **T053** Execute quickstart.md Scenario 1 (Collage Creation)
  - Follow manual validation steps
  - Verify all acceptance criteria
  - Document any deviations
  - **Acceptance**: All steps pass
  - **Test**: Manual execution of quickstart.md Scenario 1
  - **Rollback**: N/A (validation only)

- [ ] **T054** Execute quickstart.md Scenario 2 (Photo Upload)
  - Follow manual validation steps
  - Verify 10MB limit enforcement
  - Verify duplicate detection
  - **Acceptance**: All steps pass
  - **Test**: Manual execution of quickstart.md Scenario 2
  - **Rollback**: N/A (validation only)

- [ ] **T055** Execute quickstart.md Scenario 3 (Photo Resizing)
  - Follow manual validation steps
  - Verify 60fps performance
  - Verify last-write-wins concurrency
  - **Acceptance**: All steps pass
  - **Test**: Manual execution of quickstart.md Scenario 3
  - **Rollback**: N/A (validation only)

- [ ] **T056** Execute quickstart.md Scenario 4 (Access Control)
  - Follow manual validation steps
  - Verify server-side enforcement
  - Verify rw_guid not exposed in read-only responses
  - **Acceptance**: All steps pass
  - **Test**: Manual execution of quickstart.md Scenario 4
  - **Rollback**: N/A (validation only)

- [ ] **T057** Execute quickstart.md Scenario 5 (Deletion)
  - Follow manual validation steps
  - Verify cascade deletion
  - Verify confirmation dialogs
  - **Acceptance**: All steps pass
  - **Test**: Manual execution of quickstart.md Scenario 5
  - **Rollback**: N/A (validation only)

- [ ] **T058** Execute quickstart.md Scenario 6 (Performance)
  - Run Lighthouse tests
  - Verify <100ms page load
  - Verify 60fps drag-and-drop
  - **Acceptance**: Performance targets met
  - **Test**: Manual execution of quickstart.md Scenario 6
  - **Rollback**: N/A (validation only)

- [ ] **T059** Run security audit with bundler-audit
  - Install `gem install bundler-audit`
  - Run `bundle audit`
  - Fix any critical or high vulnerabilities
  - **Acceptance**: No critical/high vulnerabilities
  - **Test**: `bundle audit`
  - **Rollback**: `git checkout Gemfile*`

- [ ] **T060** Update documentation
  - Update README.md with Rails 7.2 setup
  - Update CLAUDE.md with latest technologies
  - Document Docker deployment
  - **Acceptance**: Documentation reflects current stack
  - **Test**: Manual review
  - **Rollback**: `git checkout README.md CLAUDE.md`

- [ ] **T061** Create Docker configuration
  - Create `Dockerfile` with Ruby 3.3 + libvips
  - Create `docker-compose.yml` with MongoDB service
  - Test local Docker deployment
  - **Acceptance**: `docker-compose up` works
  - **Test**: `docker-compose up && curl http://localhost:3000`
  - **Rollback**: `rm Dockerfile docker-compose.yml`

- [ ] **T062** Tag final release: `modernization-complete`
  - **Acceptance**: All 53 FRs validated, all tests pass
  - **Test**: `bundle exec rspec && rails server`
  - **Rollback**: `git tag -d modernization-complete`

---

## Dependencies

### Sequential Dependencies (Critical Path)
```
P0 (T001-T007) → P1 (T008-T019) → P2 (T020-T034) → P3 (T035-T044) → P5 (T053-T062)
                                  ↓
                                  P4 (T045-T052) → P5
```

### Within-Phase Dependencies
- **P0**: All tasks [P] except T007 (depends on T001-T006)
- **P1**: Sequential (each Rails version depends on previous)
- **P2**: T026-T030 [P] (contract tests), then T031-T032 (controllers)
- **P3**: T035 first, then T036-T043 mostly independent
- **P4**: All tasks [P] except T052 (checkpoint)
- **P5**: T053-T058 [P], then T059-T062 sequential

### Blocking Relationships
- T031 blocked by T026, T027, T028 (contract tests must exist first)
- T032 blocked by T029, T030 (contract tests must exist first)
- T041 blocked by T036, T037, T038, T039, T040 (Hotwire must work first)
- All P5 tasks blocked by P1, P2, P3 completion

---

## Parallel Execution Examples

### Characterization Phase (P0)
```bash
# Run T002-T006 in parallel
Task: "Create characterization tests for Collage CRUD in spec/models/collage_spec.rb"
Task: "Create characterization tests for Photo model in spec/models/photo_spec.rb"
Task: "Document legacy JavaScript behavior in docs/characterization/frontend-baseline.md"
Task: "Export production MongoDB schema to docs/characterization/mongodb-schema.json"
Task: "Create performance baseline in docs/characterization/performance-baseline.md"
```

### Contract Tests (P2)
```bash
# Run T026-T030 in parallel
Task: "Write contract test for POST /collages in spec/requests/collages_create_spec.rb"
Task: "Write contract test for GET /collages/{guid} in spec/requests/collages_show_spec.rb"
Task: "Write contract test for DELETE /collages/{guid} in spec/requests/collages_destroy_spec.rb"
Task: "Write contract test for POST /collages/{guid}/photos in spec/requests/photos_create_spec.rb"
Task: "Write contract test for PATCH /collages/{guid}/photos/{id} in spec/requests/photos_update_spec.rb"
```

### Testing Modernization (P4)
```bash
# Run T045-T051 in parallel
Task: "Upgrade RSpec 2.14 → 6.1"
Task: "Upgrade Capybara 0.4 → 3.x"
Task: "Remove deprecated test gems"
Task: "Migrate Cucumber scenarios to RSpec system tests"
Task: "Add performance benchmarks in spec/performance/"
Task: "Set up SimpleCov for coverage reporting"
Task: "Add committee gem for OpenAPI contract validation"
```

---

## Validation Checklist

*GATE: Must pass before marking modernization complete*

- [ ] All 53 functional requirements validated (quickstart.md scenarios pass)
- [ ] All 6 non-functional requirements met (<100ms, 60fps, etc.)
- [ ] Zero regressions from legacy behavior
- [ ] Test suite passes with >90% coverage
- [ ] No critical or high security vulnerabilities
- [ ] All contract tests pass (OpenAPI schema validation)
- [ ] Performance benchmarks within target ranges
- [ ] MongoDB data integrity checks pass
- [ ] Docker deployment works
- [ ] Documentation updated

---

## Rollback Plan

**Per-Phase Rollback**:
- P0: Delete `docs/characterization/`, remove git tag
- P1: Revert to `characterization-complete` tag, downgrade Ruby/Rails
- P2: Revert to `rails-7.2-mongoid-9-stable` tag, restore CarrierWave
- P3: Revert to `backend-modernized` tag, restore Backbone.js
- P4: Revert Gemfile, restore Cucumber
- P5: N/A (validation only)

**Database Rollback**:
```bash
# Restore MongoDB from backup
mongorestore --db collaged_production dump/collaged_production

# Revert ActiveStorage migration
rails db:rollback STEP=1
```

**Image Rollback**:
- Original CarrierWave files retained for 90 days
- Dual-read pattern allows seamless fallback

---

## Notes

- **[P] marker**: Tasks can run in parallel (different files, no dependencies)
- **Checkpoint tags**: Create git tags after each phase for easy rollback
- **Test-first approach**: Contract tests (T026-T030) written BEFORE controller updates
- **Incremental validation**: Run test suite after each task
- **Constitutional compliance**: All tasks respect feature preservation principle

---

**Status**: ✅ Tasks.md complete - Ready for implementation
**Estimated Duration**: 6-8 weeks (1 week per phase, assuming 1-2 tasks per day)
**Risk Level**: Low-Medium (incremental approach with rollback points)
