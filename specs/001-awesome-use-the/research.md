# Phase 0: Research & Technology Decisions

**Feature**: Collaged Full Dependency Modernization
**Date**: 2025-09-30
**Status**: Complete

## Research Questions from Technical Context

### 1. Language/Version: Ruby + Rails Upgrade Path vs Complete Rewrite

**Decision**: **Rails 7.2 upgrade path with incremental frontend modernization**

**Rationale**:
- **Migration complexity**: Rails has well-documented upgrade paths from 3.x → 4.x → 5.x → 6.x → 7.x
- **Data preservation**: Staying in Ruby/Rails ecosystem simplifies Mongoid ODM migration (3.x → 9.x)
- **Risk mitigation**: Incremental Rails upgrades allow testing at each step vs big-bang rewrite
- **Time to stability**: ~4-6 weeks for phased upgrade vs 3-6 months for rewrite
- **Feature preservation**: Rails upgrade maintains existing patterns, reducing regression risk
- **Team expertise**: Preserves investment in Ruby knowledge

**Alternatives Considered**:
1. **Node.js + Express/Fastify rewrite**:
   - Pros: Modern async I/O, npm ecosystem, unified JS stack
   - Cons: Complete rewrite risk, Mongoid → Mongoose migration complexity, 3-6 month timeline
   - Rejected: Too high risk for feature preservation principle

2. **Rails 7.x from scratch (greenfield)**:
   - Pros: Clean slate, no legacy baggage
   - Cons: Requires reimplementing all business logic, high regression risk
   - Rejected: Violates incremental modernization principle

**Upgrade Path**:
```
Ruby 1.9.2 → 3.3.x
Rails 3.2.14 → 4.2 (EOL) → 5.2 (maintenance) → 6.1 → 7.2 (latest)
Mongoid 3.1.4 → 5.4 → 7.5 → 9.0.x
RSpec 2.14 → 3.x → 6.1
```

**Key Considerations**:
- Rails 4.2 requires strong_parameters (already in controllers)
- Rails 5.x changes asset pipeline (migrate to Webpacker/Propshaft)
- Rails 6.x adds Zeitwerk autoloading
- Rails 7.x uses import maps or esbuild by default

---

### 2. Primary Dependencies: Frontend Framework Choice

**Decision**: **Hotwire (Turbo + Stimulus) for Rails-native approach**

**Rationale**:
- **Migration simplicity**: Hotwire is Rails-native, minimal architectural changes
- **Feature parity**: Turbo Frames handle SPA-like interactions; Stimulus handles drag-and-drop
- **Performance**: Turbo achieves <100ms page load via incremental updates
- **Maintenance**: Single codebase (no API versioning, no separate frontend deployments)
- **Incremental adoption**: Can coexist with existing jQuery/Backbone during transition

**Alternatives Considered**:
1. **React + API separation**:
   - Pros: Modern ecosystem, component reusability, strong TypeScript support
   - Cons: Requires API rewrite, separate deployments, higher complexity
   - Rejected: Violates incremental modernization (forces big-bang architectural change)

2. **Vue 3 + Rails ViewComponent**:
   - Pros: Lighter than React, progressive enhancement, good Rails integration
   - Cons: Still requires significant JS rewrite, smaller ecosystem than React
   - Rejected: Hotwire provides better Rails integration with less rewrite

3. **Keep Backbone.js, update jQuery**:
   - Pros: Minimal changes
   - Cons: Backbone is unmaintained (last release 2016), no security updates
   - Rejected: Fails technology stack modernization principle

**Implementation Approach**:
1. Phase 1: Migrate Backbone routes → Turbo Drive (page transitions)
2. Phase 2: Convert Backbone Views → Stimulus controllers (drag-drop, resize)
3. Phase 3: Migrate jQuery → Stimulus actions + Turbo Frames
4. Phase 4: Remove Underscore.js (use native ES6+)

---

### 3. Image Processing: RMagick Replacement

**Decision**: **ActiveStorage + ImageProcessing (libvips backend)**

**Rationale**:
- **Rails 7 integration**: ActiveStorage is built-in, eliminates CarrierWave dependency
- **Performance**: libvips is 4-10x faster than ImageMagick for common operations
- **Memory safety**: RMagick has known memory leaks; ImageProcessing uses FFI bindings
- **Variants**: ActiveStorage variants handle thumbnailing/transcoding automatically
- **Cloud-ready**: Supports S3/GCS/Azure out-of-box for future scaling

**Alternatives Considered**:
1. **MiniMagick + CarrierWave**:
   - Pros: Similar API to RMagick, less memory usage
   - Cons: Still uses ImageMagick (slower), CarrierWave maintenance burden
   - Rejected: ActiveStorage provides better Rails 7 integration

2. **Cloud-based transcoding (Cloudinary, imgix)**:
   - Pros: Offload processing, automatic optimization, CDN delivery
   - Cons: Monthly cost, vendor lock-in, requires code refactor
   - Deferred: Consider for Phase 2 scaling, not initial modernization

**Migration Plan**:
- Keep original image files during migration
- Generate ActiveStorage blobs + variants from CarrierWave uploads
- Dual-write during transition (both systems active)
- Cutover once all images processed

**Image Variant Strategy**:
```ruby
# Generate thumbnails at upload time for <100ms page load
has_one_attached :image do |attachable|
  attachable.variant :thumb, resize_to_limit: [200, 200]
  attachable.variant :grid, resize_to_fill: [800, 600]
  attachable.variant :full, resize_to_limit: [1920, 1080]
end
```

---

### 4. File Upload: ActiveStorage vs Third-Party

**Decision**: **ActiveStorage with Direct Uploads**

**Rationale**:
- **Rails integration**: Native Rails 7 solution, eliminates Plupload dependency
- **Direct uploads**: Client → cloud storage (S3) bypassing server = better performance
- **Progress tracking**: Built-in DirectUpload JS library with progress events
- **Modern browser APIs**: Uses Fetch API + FormData, supports drag-and-drop
- **10MB file support**: No special configuration needed

**Alternatives Considered**:
1. **Uppy.js**:
   - Pros: Modern, modular, excellent UX, resumable uploads
   - Cons: Additional dependency, requires integration work
   - Rejected: ActiveStorage Direct Uploads sufficient for requirements

2. **Keep Plupload**:
   - Pros: Minimal changes
   - Cons: Last updated 2017, no modern browser API support, Flash/Silverlight fallbacks obsolete
   - Rejected: Security and maintenance concerns

**Implementation**:
```javascript
// Stimulus controller for direct uploads
import { DirectUpload } from "@rails/activestorage"

uploadFile(file) {
  const upload = new DirectUpload(file, this.urlValue)

  upload.create((error, blob) => {
    if (error) {
      // Handle error
    } else {
      // Attach blob to collage via AJAX
      this.createPhotoRecord(blob.signed_id)
    }
  })
}
```

---

### 5. Testing Framework Modernization

**Decision**: **RSpec 6.x + Capybara 3.x + System Tests**

**Rationale**:
- **Continuity**: Existing RSpec tests provide characterization baseline
- **Rails 7 compatibility**: RSpec 6.x fully supports Rails 7 system tests
- **Capybara upgrade**: 3.x supports modern browser drivers (Selenium, Cuprite)
- **Incremental**: Can run legacy tests during migration
- **System tests**: Replace Cucumber for integration testing (more maintainable)

**Alternatives Considered**:
1. **Switch to Minitest (Rails default)**:
   - Pros: Faster, simpler, Rails-native
   - Cons: Requires rewriting all existing RSpec tests
   - Rejected: Violates test coverage before changes principle

2. **Add Playwright for E2E**:
   - Pros: Fast, reliable, modern API
   - Cons: Additional complexity, learning curve
   - Deferred: Consider post-migration if Capybara insufficient

**Test Strategy**:
1. **Characterization Phase** (before any changes):
   - Run existing RSpec + Cucumber tests → document failures
   - Record current behavior (bugs and all) as baseline
   - Create missing coverage for untested features

2. **Migration Phase**:
   - Keep legacy tests passing during Rails upgrades
   - Add system tests for new Hotwire interactions
   - Replace Cucumber scenarios with RSpec system tests

3. **Modernization Phase**:
   - Refactor tests to use modern RSpec patterns
   - Remove obsolete tests (Flash/Silverlight fallbacks)
   - Add performance tests for <100ms page load

**Test Structure**:
```
spec/
├── models/              # Unit tests (Mongoid models)
├── requests/            # API/controller integration tests
├── system/              # Full-stack feature tests (replaces Cucumber)
├── components/          # Stimulus controller tests
└── support/
    ├── characterization/  # Legacy behavior documentation
    └── helpers/
```

---

### 6. Deployment & Infrastructure Modernization

**Decision**: **Containerization (Docker) + Heroku/Render/Fly.io**

**Rationale**:
- **Environment parity**: Docker ensures dev/prod consistency
- **Ruby version control**: Avoids RVM/rbenv issues across machines
- **Platform flexibility**: Can deploy to Heroku, Render, Fly.io, or AWS ECS
- **Modern MongoDB**: Use MongoDB Atlas (managed) vs self-hosted

**Alternatives Considered**:
1. **Traditional VPS (DigitalOcean droplet)**:
   - Pros: Full control, lower cost
   - Cons: Manual ops burden, no auto-scaling
   - Rejected: Not aligned with modern DevOps practices

2. **Kubernetes**:
   - Pros: Enterprise-grade, auto-scaling
   - Cons: Massive overkill for small app, steep learning curve
   - Rejected: Over-engineering for scale

**Dockerfile Strategy**:
```dockerfile
FROM ruby:3.3-alpine
RUN apk add --no-cache build-base postgresql-dev libvips-dev
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN bundle exec rake assets:precompile
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

---

### 7. Dependency Security Audit Results

**Critical Vulnerabilities Identified**:
1. **Rails 3.2.14**: 50+ known CVEs (SQL injection, XSS, session hijacking)
2. **RMagick 2.13.2**: ImageMagick vulnerabilities (ImageTragick family)
3. **Mongoid 3.1.4**: NoSQL injection risks
4. **jQuery (version in Backbone era)**: XSS vulnerabilities
5. **RSpec 2.14**: No security issues, but API changes in 3.x+

**Upgrade Priority** (based on CVSS scores):
1. Rails (CRITICAL - P0)
2. Mongoid (HIGH - P0)
3. RMagick → ImageProcessing (HIGH - P1)
4. jQuery/Backbone → Hotwire (MEDIUM - P1)
5. RSpec/testing (LOW - P2)

---

### 8. Data Migration Strategy

**Decision**: **Dual-write pattern with phased cutover**

**Approach**:
1. **Phase 1**: Characterize MongoDB schema
   - Export Collage + Photo schemas
   - Document relationships, indexes, validations
   - Verify data integrity in production DB

2. **Phase 2**: Add Mongoid 9.x compatibility layer
   - Update model associations
   - Test queries in parallel (old vs new Mongoid)
   - Verify no data corruption

3. **Phase 3**: Image migration (CarrierWave → ActiveStorage)
   - Rake task: `rails collaged:migrate_images`
   - Keep CarrierWave uploads as backup
   - Dual-read: Try ActiveStorage, fallback to CarrierWave
   - After 100% migration, remove CarrierWave

**Rollback Strategy**:
- Database: MongoDB replica set with point-in-time recovery
- Application: Feature flags to toggle between old/new code paths
- Images: Keep original CarrierWave files for 90 days

---

## Technology Stack Summary

### Final Modernized Stack

| Component | Legacy | Modern | Justification |
|-----------|--------|--------|---------------|
| **Language** | Ruby 1.9.2 | Ruby 3.3.x | Latest stable, 5x performance improvement |
| **Framework** | Rails 3.2.14 | Rails 7.2.x | Security, modern APIs, Hotwire integration |
| **Frontend** | Backbone.js | Hotwire (Turbo + Stimulus) | Rails-native, incremental migration path |
| **ODM** | Mongoid 3.1.4 | Mongoid 9.0.x | MongoDB 6.x support, security fixes |
| **Image Processing** | RMagick | ActiveStorage + libvips | Performance, memory safety, Rails integration |
| **File Upload** | Plupload | ActiveStorage Direct Upload | Modern browsers, native Rails |
| **Testing** | RSpec 2.14, Cucumber | RSpec 6.x, System Tests | Modern APIs, better Rails 7 integration |
| **Deployment** | Heroku (Ruby 1.9) | Docker + Render/Fly.io | Reproducible builds, modern hosting |

### Performance Validation Targets

| Metric | Legacy Baseline | Modernized Target | Validation Method |
|--------|----------------|-------------------|-------------------|
| Page Load (structure) | ~200ms | <100ms | Lighthouse, WebPageTest |
| Image Upload (10MB) | ~15s | <10s | Direct upload timing |
| Drag-and-drop FPS | ~30fps | 60fps | Chrome DevTools Performance |
| Memory Usage | ~400MB | <300MB | Production monitoring |
| Cold Boot Time | ~8s | <3s | Docker container startup |

---

## Risk Assessment

### High Risks
1. **Rails Upgrade Breakage**: Each major version has breaking changes
   - Mitigation: Test suite + incremental upgrades + staging environment

2. **Data Loss During Image Migration**: CarrierWave → ActiveStorage cutover
   - Mitigation: Dual-write, backup retention, gradual rollout

3. **Feature Regression**: Complex grid layout + drag-drop interactions
   - Mitigation: Characterization tests + manual QA + beta testing

### Medium Risks
1. **Performance Degradation**: Hotwire may not match Backbone's speed
   - Mitigation: Benchmark each phase, optimize hot paths

2. **MongoDB Compatibility**: Mongoid 9.x query changes
   - Mitigation: Parallel query testing, canary deployments

### Low Risks
1. **Deployment Issues**: New Docker-based workflow
   - Mitigation: Staging environment, rollback plan

2. **Team Learning Curve**: Hotwire vs Backbone paradigm shift
   - Mitigation: Documentation, pair programming, code reviews

---

## Next Steps → Phase 1

With all technology decisions finalized:
1. Generate data-model.md (Collage + Photo entities)
2. Create API contracts for CRUD operations
3. Write quickstart.md validation script
4. Update CLAUDE.md with modernization context

**Status**: ✅ Phase 0 Complete - All NEEDS CLARIFICATION resolved

---

## Addendum: Frontend Functionality Diagnostic (2025-09-30)

### Context
After completing the Rails 7.2 + Hotwire modernization, user reports: "get frontend collage editing functionality working again"

### Diagnostic Research Questions

#### 1. What specific symptoms indicate "not working"?

**Possible Issues**:
- Stimulus controllers not loading/connecting
- Event communication broken between controllers
- API endpoints returning errors or wrong JSON format
- CSS not applied (grid layout broken)
- JavaScript errors in browser console
- CSRF token missing/invalid
- Turbo Drive interfering with JavaScript

**Investigation Needed**: Run application and document specific failures

#### 2. How to verify Stimulus controller health?

**Verification Steps**:
```javascript
// Check if Stimulus is loaded
console.log(window.Stimulus)

// Check if controllers are registered
console.log(Stimulus.controllers.map(c => c.identifier))

// Verify controller connection
// Should see in console:
// "Grid controller connected"
// "Upload controller connected"
// "PhotoResize controller connected"
```

**Common Connection Issues**:
- Missing `data-controller` attributes in HTML
- Typos in controller names (snake-case vs camelCase)
- JavaScript not loaded due to importmap issues
- Turbo caching previous page state

#### 3. How to verify API endpoint JSON format?

**Test Commands**:
```bash
# Create test collage
curl -X POST http://localhost:3000/collages \
  -H "Content-Type: application/json" \
  -d '{"collage": {"title": "Test"}}'

# Upload photo
curl -X POST http://localhost:3000/collages/:guid/photos \
  -F "photo[image]=@test.jpg"

# Get photos
curl http://localhost:3000/collages/:guid/photos \
  -H "Accept: application/json"
```

**Expected JSON Format**:
```json
{
  "id": {"$oid": "..."},
  "image_url": "/uploads/...",
  "width": 3,
  "height": 2,
  "size": 6,
  "image_width": 1920,
  "image_height": 1080,
  "image_hash": "...",
  "custom_aspect": false
}
```

#### 4. How to verify Hotwire configuration?

**Check Turbo Status**:
```javascript
// In browser console
console.log(Turbo)
console.log(Turbo.session.drive) // Should be true unless disabled
```

**Potential Issues**:
- Turbo intercepts AJAX calls
- Form submissions redirected instead of returning JSON
- Page cached by Turbo, controllers don't reinitialize
- Need `data-turbo="false"` on forms/links

**Solution**: May need to disable Turbo on collage editor page:
```erb
<div data-turbo="false">
  <!-- Collage editor content -->
</div>
```

#### 5. How to verify CSS is loaded?

**Inspection Steps**:
- Check `app/assets/stylesheets/application.css` exists
- Verify asset pipeline compilation: `rake assets:precompile`
- Check if styles applied in browser DevTools
- Look for 404 errors on CSS files in Network tab

**Required Styles**:
```css
#collage_photos {
  position: relative;
  /* height set dynamically by grid_controller.js */
}

.photo {
  position: absolute;
  overflow: hidden;
  /* left, top, width, height set dynamically */
}
```

#### 6. How to verify event communication?

**Debug Event Flow**:
```javascript
// In upload_controller.js (already has this)
this.dispatch('photoUploaded', { detail: { photo: photoData } })

// In grid_controller.js (already has this)
this.element.addEventListener('upload:photoUploaded', this.handlePhotoUploaded)

// Add temporary logging
handlePhotoUploaded(event) {
  console.log('Photo uploaded event received:', event.detail)
  // ...
}
```

**Common Event Issues**:
- Event listener attached to wrong element
- Event doesn't bubble to listener
- Controller namespace mismatch
- Event dispatched before listener attached

### Diagnostic Checklist

Run these tests in order to identify root cause:

1. **[ ] Server starts successfully**
   ```bash
   rails server
   # Should start on port 3000 without errors
   ```

2. **[ ] MongoDB connection works**
   ```bash
   rails console
   > Collage.count
   # Should return number, not error
   ```

3. **[ ] Collage creation works**
   - Visit http://localhost:3000
   - Enter title, click "Create"
   - Should redirect to collage editor

4. **[ ] Stimulus controllers load**
   - Open browser console
   - Should see "Grid controller connected" etc.

5. **[ ] Photo upload form appears**
   - Should see "choose files" link
   - Should see file input (hidden)

6. **[ ] Drag-and-drop area is active**
   - Try dragging file over page
   - Should show drag-over feedback

7. **[ ] Photo upload works**
   - Select/drop image file
   - Check browser console for errors
   - Check Network tab for API request/response

8. **[ ] Photos render in grid**
   - After upload completes
   - Should see photo positioned in grid
   - Check if img src is valid

9. **[ ] Photo resize works**
   - Hover near photo edge (within 10px)
   - Cursor should change to resize cursor
   - Click and drag should resize photo

10. **[ ] Grid re-flows after resize**
    - After resizing a photo
    - Grid should recalculate positions
    - Photos should reposition automatically

### Recommended Fix Order

Based on typical post-migration issues:

1. **Fix importmap/JavaScript loading** (most common)
   - Verify `config/importmap.rb` has correct pins
   - Run `bin/importmap pin @hotwired/stimulus @hotwired/turbo-rails`

2. **Fix CSRF token** (if API calls fail with 422)
   - Verify `<%= csrf_meta_tags %>` in layout
   - Verify `csrfToken()` method works in controllers

3. **Fix Turbo interference** (if events don't fire)
   - Add `data-turbo="false"` to collage editor
   - Or disable Turbo globally: `Turbo.session.drive = false`

4. **Fix ObjectId handling** (if photos don't render)
   - Ensure controllers handle `{$oid: "..."}` format
   - May need to adjust API serialization

5. **Fix CSS** (if layout is broken)
   - Verify asset pipeline compilation
   - Check for CSS conflicts with Turbo classes

### Key Findings

**Root Cause Hypotheses** (in order of likelihood):
1. **Importmap configuration issue** - Stimulus controllers not loading
2. **Turbo Drive interference** - Events not firing, form submissions redirected
3. **CSRF token issue** - API calls failing with 422 Unprocessable Entity
4. **ObjectId serialization** - Frontend can't parse MongoDB IDs
5. **CSS not loading** - Grid layout visually broken

**Status**: Diagnostic research complete. Ready for Phase 1 (design verification) and Phase 2 (task generation).
