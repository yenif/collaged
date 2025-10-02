# Quickstart: Collaged Feature Validation

**Feature**: Full Dependency Modernization
**Purpose**: Validate all 53 functional requirements are preserved after modernization
**Target**: Rails 7.2 + Hotwire + Mongoid 9.x + ActiveStorage

## Prerequisites

**Environment**:
```bash
# Ruby & Rails
ruby -v  # Should be 3.3.x
rails -v # Should be 7.2.x

# MongoDB
mongod --version  # Should be 6.x or 7.x
mongo --eval 'db.version()' # Verify connectivity

# Dependencies
bundle install
rails db:mongoid:create_indexes

# Assets (if using Propshaft/import maps)
rails assets:precompile
```

**Test Database Setup**:
```bash
# Clean slate
RAILS_ENV=test rails db:mongoid:drop
RAILS_ENV=test rails db:mongoid:create_indexes
RAILS_ENV=test rails db:seed  # Optional: load sample data
```

---

## Manual Validation Scenarios

### Scenario 1: Collage Creation (FR-001 to FR-006)

**Start Application**:
```bash
rails server
# Navigate to http://localhost:3000
```

**Steps**:
1. ✅ Open homepage → should display collage creation form
2. ✅ Enter title "Test Collage" → click Create
3. ✅ Verify redirect to collage page with two URLs displayed
4. ✅ Check browser URL contains GUID (rw_guid for creator)
5. ✅ Verify title "Test Collage" appears in header
6. ✅ Copy read-only URL (r_guid) → open in incognito window
7. ✅ Verify upload button hidden in read-only view
8. ✅ Try blank title → should show validation error

**Expected Results**:
- Collage created with two unique GUIDs
- Write access URL shows edit controls
- Read-only URL hides edit controls
- Title validation enforced

**API Validation**:
```bash
# Create collage via API
curl -X POST http://localhost:3000/collages \
  -H "Content-Type: application/json" \
  -d '{"title":"API Test Collage"}'

# Response should include:
# - "r_guid": "[uuid]"
# - "rw_guid": "[uuid]"
# - "write_access": true
# - HTTP 201 Created

# Try blank title
curl -X POST http://localhost:3000/collages \
  -H "Content-Type: application/json" \
  -d '{"title":""}'

# Should return HTTP 422 with error
```

---

### Scenario 2: Photo Upload (FR-010 to FR-020)

**Preparation**:
```bash
# Download test images or use samples
mkdir -p tmp/test_images
# Place 3-5 JPG/PNG files in tmp/test_images/
ls tmp/test_images/*.jpg
```

**Steps**:
1. ✅ Navigate to collage with write access
2. ✅ Click "choose files" button
3. ✅ Select 3 images → verify file list appears
4. ✅ Watch progress indicators update (0% → 100%)
5. ✅ After upload, verify photos appear in grid
6. ✅ Check photos maintain aspect ratio
7. ✅ Verify photos placed left-to-right, top-to-bottom
8. ✅ Upload 11MB file → should fail with error
9. ✅ Try .txt file → should fail with format error
10. ✅ Upload same image twice → see duplicate warning (first time only)

**Expected Results**:
- Multi-file upload supported
- Progress tracking visible
- Automatic grid placement
- 10MB limit enforced
- JPG/JPEG/GIF/PNG only
- Duplicate detection with session-based warning

**API Validation**:
```bash
# Upload photo via API
curl -X POST http://localhost:3000/collages/[RW_GUID]/photos \
  -F "image=@tmp/test_images/photo1.jpg" \
  -F "caption=Beach sunset"

# Response should include:
# - "image_url": "/rails/active_storage/..."
# - "image_width", "image_height": original dimensions
# - "size", "width", "height": grid dimensions
# - HTTP 201 Created

# Try read-only GUID
curl -X POST http://localhost:3000/collages/[R_GUID]/photos \
  -F "image=@tmp/test_images/photo2.jpg"

# Should return HTTP 403 Forbidden
```

**Duplicate Detection Test**:
```bash
# Upload same file twice
curl -X POST http://localhost:3000/collages/[RW_GUID]/photos \
  -F "image=@tmp/test_images/photo1.jpg"

# First duplicate: HTTP 409 with show_warning:true
# Subsequent: HTTP 409 with show_warning:false
```

---

### Scenario 3: Photo Resizing (FR-029 to FR-040)

**Steps**:
1. ✅ Hover over photo edge (within 10px) → cursor changes
2. ✅ Click and drag bottom-right corner → photo expands
3. ✅ Release → grid re-flows automatically
4. ✅ Verify photo spans multiple cells
5. ✅ Check aspect ratio maintained (or custom if user changed)
6. ✅ Try resizing below 1×1 → should snap to minimum
7. ✅ Verify smooth 60fps dragging (Chrome DevTools Performance)
8. ✅ Open same collage in two tabs (write access)
9. ✅ Resize in tab 1 → save
10. ✅ Resize in tab 2 → save
11. ✅ Reload both → verify last write wins (tab 2 version)

**Expected Results**:
- Drag-and-drop resizing works
- Grid snaps to cell boundaries
- Minimum 1×1 size enforced
- 60fps performance during drag
- Concurrent edits: last-write-wins (no merge)

**API Validation**:
```bash
# Update photo dimensions
curl -X PATCH http://localhost:3000/collages/[RW_GUID]/photos/[PHOTO_ID] \
  -H "Content-Type: application/json" \
  -d '{
    "size": 12,
    "width": 3,
    "height": 4,
    "custom_aspect": true
  }'

# Should return HTTP 200 with updated photo

# Invalid dimensions (size != width * height)
curl -X PATCH http://localhost:3000/collages/[RW_GUID]/photos/[PHOTO_ID] \
  -H "Content-Type: application/json" \
  -d '{
    "size": 12,
    "width": 5,
    "height": 3
  }'

# Should return HTTP 422 validation error
```

---

### Scenario 4: Access Control (FR-036 to FR-046)

**Steps**:
1. ✅ Create collage (receives rw_guid URL)
2. ✅ Open collage → verify edit controls visible
3. ✅ Copy read-only URL (r_guid)
4. ✅ Open in incognito → verify:
   - Upload button hidden
   - Resize handles hidden
   - rw_guid not in JSON response
5. ✅ Try upload via API with r_guid → HTTP 403
6. ✅ Try photo delete via API with r_guid → HTTP 403
7. ✅ Try collage delete via API with r_guid → HTTP 403
8. ✅ Attempt to bypass UI (browser console):
   ```javascript
   fetch('/collages/[R_GUID]/photos', {
     method: 'POST',
     body: formData
   })
   ```
9. ✅ Verify server returns 403 error
10. ✅ Check error message displayed to user

**Expected Results**:
- UI hides controls for read-only access (client-side)
- Server validates and rejects write operations (server-side)
- 403 error with clear message returned
- rw_guid never exposed in read-only responses

**Security Test**:
```bash
# Verify rw_guid hidden in read-only access
curl http://localhost:3000/collages/[R_GUID]

# Response should NOT contain "rw_guid" field
# Response should have "write_access": false
```

---

### Scenario 5: Deletion (FR-007 to FR-009, FR-021, FR-022)

**Steps**:
1. ✅ Navigate to collage with write access
2. ✅ Verify delete button visible
3. ✅ Click delete button → confirmation dialog appears
4. ✅ Cancel → collage remains
5. ✅ Click delete → confirm
6. ✅ Verify redirect to homepage
7. ✅ Try accessing deleted collage URL → 404 error
8. ✅ Check MongoDB: `db.collages.find({rw_guid: "[GUID]"})` → empty
9. ✅ Create collage with photos
10. ✅ Delete individual photo → verify grid re-flows
11. ✅ Delete collage → verify all photos and image files removed

**Expected Results**:
- Delete button only visible with write access
- Confirmation dialog prevents accidents
- Collage and all photos permanently removed
- Image files cleaned up (ActiveStorage)
- 404 returned for deleted collages

**API Validation**:
```bash
# Delete collage via API
curl -X DELETE http://localhost:3000/collages/[RW_GUID]

# Should return HTTP 204 No Content

# Verify deletion
curl http://localhost:3000/collages/[RW_GUID]

# Should return HTTP 404 Not Found

# Try delete with read-only GUID
curl -X DELETE http://localhost:3000/collages/[R_GUID]

# Should return HTTP 403 Forbidden
```

---

### Scenario 6: Performance (NFR-001 to NFR-004)

**Lighthouse Test**:
```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Test collage page load
lighthouse http://localhost:3000/collages/[GUID] \
  --only-categories=performance \
  --output=html \
  --output-path=./tmp/lighthouse-report.html

# Verify metrics:
# - Time to Interactive: <100ms for page structure
# - First Contentful Paint: <100ms
# - Largest Contentful Paint: <2.5s (with progressive image loading)
```

**Manual Performance Check**:
1. ✅ Open Chrome DevTools → Performance tab
2. ✅ Start recording → reload collage page
3. ✅ Verify page interactive within 100ms
4. ✅ Check images load progressively (thumbnails first)
5. ✅ Test drag-and-drop → verify 60fps (no frame drops)
6. ✅ Upload 10MB image → verify transcode to smaller variants

**Expected Results**:
- Page structure loads <100ms
- Progressive image loading (thumb → grid → full)
- 60fps drag interactions
- Automatic image optimization

**WebPageTest**:
```bash
# Run WebPageTest (requires API key or public instance)
# https://www.webpagetest.org/
# Target URL: http://localhost:3000/collages/[GUID]

# Verify:
# - Start Render: <100ms
# - Speed Index: <1000ms
# - Time to Interactive: <100ms (excluding image downloads)
```

---

## Automated Test Suite

**Run Full Test Suite**:
```bash
# Unit tests (models, helpers)
bundle exec rspec spec/models
bundle exec rspec spec/helpers

# Request tests (controllers, API)
bundle exec rspec spec/requests

# System tests (full-stack, browser)
bundle exec rspec spec/system

# All tests
bundle exec rspec

# With coverage
COVERAGE=true bundle exec rspec
open coverage/index.html  # View coverage report
```

**Expected Results**:
- All tests pass (green)
- >90% code coverage
- No deprecation warnings
- Tests run in <60 seconds

**Contract Tests**:
```bash
# If using committee gem for OpenAPI validation
bundle exec rspec spec/contracts

# Validates:
# - All API responses match OpenAPI schema
# - Required fields present
# - Type validation (string, integer, etc.)
# - HTTP status codes correct
```

---

## Data Integrity Validation

**MongoDB Checks**:
```javascript
// Connect to MongoDB
mongo collaged_development

// Check collage GUID uniqueness
db.collages.aggregate([
  { $group: { _id: "$r_guid", count: { $sum: 1 } } },
  { $match: { count: { $gt: 1 } } }
])
// Should return empty array

db.collages.aggregate([
  { $group: { _id: "$rw_guid", count: { $sum: 1 } } },
  { $match: { count: { $gt: 1 } } }
])
// Should return empty array

// Verify photo grid constraints
db.collages.aggregate([
  { $unwind: "$photos" },
  { $project: {
      valid: { $eq: [
        { $multiply: ["$photos.width", "$photos.height"] },
        "$photos.size"
      ]}
  }},
  { $match: { valid: false } }
])
// Should return empty (all photos satisfy width × height = size)

// Check image hash existence
db.collages.aggregate([
  { $unwind: "$photos" },
  { $match: { "photos.image_hash": { $exists: false } } }
])
// Should return empty (all photos have hashes)
```

**ActiveStorage Checks**:
```ruby
# Rails console
rails console

# Verify all photos have images
Photo.where(:image.exists => false).count  # Should be 0

# Check variant generation
photo = Photo.first
photo.image.variant(:thumb).processed?  # Should be true
photo.image.variant(:grid).processed?   # Should be true
photo.image.variant(:full).processed?   # Should be true

# Verify blob storage
ActiveStorage::Blob.count >= Photo.count  # Should be true
```

---

## Regression Testing Checklist

After completing modernization, verify these specific behaviors are **unchanged**:

**Grid Layout**:
- [ ] Prime factorization algorithm produces same width/height splits
- [ ] Photos snap to grid boundaries identically
- [ ] Left-to-right, top-to-bottom placement order preserved
- [ ] Vertical expansion when row full

**Image Processing**:
- [ ] Aspect ratio calculations match legacy (compare pixel-perfect)
- [ ] Image hash algorithm (SHA1) produces same hashes
- [ ] Thumbnail generation quality comparable

**Access Control**:
- [ ] GUID generation produces UUID v4 format (same as UUIDTools)
- [ ] Read/write URL behavior identical
- [ ] 403 errors returned for unauthorized actions

**Edge Cases**:
- [ ] 10MB upload limit enforced
- [ ] Grid handles 1×1 minimum size
- [ ] Concurrent edits: last-write-wins (no merge)
- [ ] Duplicate detection works across sessions

---

## Rollback Verification

**If issues found, verify rollback works**:
```bash
# Revert migrations
rails db:rollback STEP=1

# Restore database from backup
mongorestore --db collaged_production dump/collaged_production

# Revert code deploy
git checkout [previous-release-tag]
bundle install
rails assets:precompile
rails restart
```

**Rollback Checklist**:
- [ ] Database restored successfully
- [ ] Code reverted to previous version
- [ ] All features working as before issue
- [ ] No data loss occurred

---

## Success Criteria

✅ **All 53 functional requirements validated**
✅ **All 6 non-functional requirements met**
✅ **Zero regressions from legacy behavior**
✅ **Performance targets achieved (<100ms, 60fps)**
✅ **Test suite passes (>90% coverage)**
✅ **Security: access control enforced**
✅ **Data integrity: MongoDB constraints validated**

**Sign-off**: Ready for production deployment when all scenarios pass.

---

## Troubleshooting

**Common Issues**:

1. **Upload fails with 422**:
   - Check file size (<10MB)
   - Verify format (JPG/JPEG/GIF/PNG only)
   - Check ActiveStorage configuration

2. **Images not loading**:
   - Verify `rails active_storage:install` run
   - Check blob storage (local or S3 configured)
   - Inspect ActiveStorage::Blob records

3. **Grid layout broken**:
   - Check Integer#factors method present
   - Verify Stimulus controller loaded
   - Inspect browser console for JS errors

4. **Tests failing**:
   - Run `rails db:test:prepare`
   - Check factory_bot factories valid
   - Verify MongoDB indexes created

5. **Performance issues**:
   - Check MongoDB indexes: `db.collages.getIndexes()`
   - Verify image variants pre-generated
   - Enable Rails cache in development

**Logs**:
```bash
tail -f log/development.log  # Application logs
tail -f log/test.log         # Test logs
tail -f /var/log/mongodb/mongod.log  # MongoDB logs
```

---

---

## Addendum: Photo Reordering Validation (2025-10-01)

### Scenario 7: Drag-and-Drop Photo Reordering

**Purpose**: Validate restored photo reordering functionality using HTML5 Drag and Drop API

**Steps**:
1. ✅ Navigate to collage with write access containing 5+ photos
2. ✅ Verify photos displayed in ordinal order (check ordinal field in JSON)
3. ✅ Hover over photo (not near edge) → cursor should show drag cursor
4. ✅ Click and drag photo #1 → drag over photo #3
5. ✅ Verify visual feedback during drag:
   - Dragged photo opacity reduced (50%)
   - Drop target highlighted (blue dashed border)
   - Cursor shows "grabbing" state
6. ✅ Release mouse → drop photo
7. ✅ Verify grid re-flows with new photo order
8. ✅ Reload page → verify new order persisted
9. ✅ Check MongoDB ordinal values updated correctly
10. ✅ Open in read-only URL → verify drag disabled (no draggable attribute)
11. ✅ Test performance: drag multiple photos → no frame drops (60fps)
12. ✅ Test interaction: drag photo, then resize same photo → both work

**Expected Results**:
- Photos reorderable via drag-and-drop
- Visual feedback during drag (opacity, cursor, highlighting)
- Grid reflows automatically after drop
- Ordinal values updated and persisted
- Drag disabled for read-only access
- 60fps performance maintained
- No conflict with resize functionality

**API Validation**:
```bash
# Get photos before reorder
curl http://localhost:3000/collages/[RW_GUID]/photos | jq '.[] | {id, ordinal}'

# Example output:
# { "id": {"$oid": "507f1f77bcf86cd799439011"}, "ordinal": 1 }
# { "id": {"$oid": "507f1f77bcf86cd799439012"}, "ordinal": 2 }
# { "id": {"$oid": "507f1f77bcf86cd799439013"}, "ordinal": 3 }

# Update ordinal (move photo 1 to position 3)
curl -X PATCH http://localhost:3000/collages/[RW_GUID]/photos/507f1f77bcf86cd799439011 \
  -H "Content-Type: application/json" \
  -d '{"photo": {"ordinal": 3}}'

# Verify response shows updated ordinal
# HTTP 200 with "ordinal": 3

# Get photos after reorder
curl http://localhost:3000/collages/[RW_GUID]/photos | jq '.[] | {id, ordinal}'

# Verify ordinals recalculated sequentially:
# { "id": {"$oid": "507f1f77bcf86cd799439012"}, "ordinal": 1 }
# { "id": {"$oid": "507f1f77bcf86cd799439013"}, "ordinal": 2 }
# { "id": {"$oid": "507f1f77bcf86cd799439011"}, "ordinal": 3 }
```

**MongoDB Validation**:
```javascript
// Connect to MongoDB
mongo collaged_development

// Check ordinals are sequential
db.collages.aggregate([
  { $unwind: "$photos" },
  { $group: {
    _id: "$_id",
    ordinals: { $push: "$photos.ordinal" }
  }},
  { $project: {
    ordinals: 1,
    is_sequential: {
      $eq: [
        "$ordinals",
        { $range: [1, { $add: [{ $size: "$ordinals" }, 1] }] }
      ]
    }
  }},
  { $match: { is_sequential: false } }
])
// Should return empty (all ordinals sequential 1,2,3,...)
```

**Performance Validation**:
```javascript
// Browser console - measure drag performance
performance.mark('drag-start')

// User drags photo

performance.mark('drag-end')
performance.measure('drag-duration', 'drag-start', 'drag-end')
console.log(performance.getEntriesByName('drag-duration')[0].duration)
// Should be multiple of ~16.67ms (60fps) and total < 1000ms
```

**Edge Cases**:
- ✅ Drag photo to first position → ordinal becomes 1
- ✅ Drag photo to last position → ordinal becomes N (total count)
- ✅ Drag photo to same position → no change
- ✅ Attempt drag with read-only access → operation prevented
- ✅ Concurrent reorder (two users) → last-write-wins (matches FR-040)
- ✅ Reorder photo that's also resized → both operations succeed

**Integration with Existing Features**:
- ✅ Reorder photos → resize one → reorder again (all work together)
- ✅ Upload new photo → automatically gets ordinal = max + 1
- ✅ Delete photo in middle → remaining ordinals recalculated
- ✅ Grid layout respects new ordinal order after reflow

**Accessibility**:
- ✅ Keyboard navigation: Tab to photo, Enter to pick up, Arrow keys to move, Enter to drop
- ✅ Screen reader: Announces "Photo X of Y" and "Moved to position Z"
- ✅ Reduced motion: Respects `prefers-reduced-motion` CSS media query

**Status**: ✅ Photo reordering validation scenario complete - Ready for Phase 2 task generation

---

**Overall Status**: ✅ Quickstart guide complete including photo reordering - Ready for Phase 2 task generation
