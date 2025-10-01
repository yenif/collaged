# Tasks: Restore Frontend Collage Editing Functionality

**Feature**: Fix frontend after Rails 7.2 + Hotwire modernization
**Branch**: `001-awesome-use-the`
**Input**: Design documents from `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/collaged-api.yaml, quickstart.md

## Overview

The Rails 7.2 + Hotwire modernization has been completed, but the user reports that "frontend collage editing functionality" needs to be "working again". This task list focuses on diagnosing and fixing specific frontend issues to restore full functionality.

**Key Focus Areas**:
- Stimulus controller loading and connectivity
- Event communication between controllers
- API endpoint JSON responses
- Turbo Drive configuration
- CSS and grid layout
- CSRF token handling

## Path Conventions

Rails 7.2 monolith at repository root:
- Controllers: `app/controllers/`
- Models: `app/models/`
- Views: `app/views/`
- JavaScript: `app/javascript/controllers/`
- Styles: `app/assets/stylesheets/`
- Tests: `spec/`
- Config: `config/`

## Phase D1: Diagnostic Tasks (Identify Root Cause)

**CRITICAL**: Complete ALL diagnostic tasks before attempting fixes. These run in parallel to identify issues quickly.

- [x] **T001** [P] Verify Rails server starts without errors
  - Run `rails server` and check startup logs
  - Verify no dependency errors or missing gems
  - Check MongoDB connection status
  - **Acceptance**: Server starts on port 3000, no errors in console
  - **Test**: `curl http://localhost:3000`
  - **Files**: N/A (diagnostic only)

- [x] **T002** [P] Test MongoDB connectivity and data integrity
  - Run `rails console` and execute `Collage.count`
  - Verify existing collages load correctly
  - Check photo embeds are accessible
  - **Acceptance**: MongoDB queries work, no Mongoid errors
  - **Test**: `rails console -e 'puts Collage.count'`
  - **Files**: N/A (diagnostic only)

- [x] **T003** [P] Verify importmap configuration and JavaScript loading
  - Check `config/importmap.rb` has correct pins for Hotwire
  - Verify `app/javascript/application.js` exists and loads
  - Run `bin/importmap audit` to check for issues
  - **Acceptance**: All JavaScript dependencies properly pinned
  - **Test**: `bin/importmap audit`
  - **Files**: `config/importmap.rb`, `app/javascript/application.js`

- [x] **T004** [P] Test Stimulus controller registration in browser console
  - Start server, navigate to collage editor
  - Open browser DevTools console
  - Check for "Grid controller connected", "Upload controller connected", "PhotoResize controller connected" logs
  - Verify `window.Stimulus` is defined
  - Verify `Stimulus.controllers.map(c => c.identifier)` shows controllers
  - **Acceptance**: All three controllers load and connect
  - **Test**: Manual browser inspection
  - **Files**: `app/javascript/controllers/*_controller.js`

- [x] **T005** [P] Inspect API endpoint responses for correct JSON format
  - Create test collage via web UI
  - Check browser Network tab for JSON responses
  - Verify ObjectId format: `{"id": {"$oid": "..."}}`
  - Test GET `/collages/:guid/photos` endpoint
  - **Acceptance**: API returns valid JSON with proper ObjectId serialization
  - **Test**: `curl http://localhost:3000/collages/:guid/photos -H "Accept: application/json"`
  - **Files**: `app/controllers/photos_controller.rb`, `app/controllers/collages_controller.rb`

- [x] **T006** [P] Check browser console for JavaScript errors
  - Navigate to collage editor page
  - Open DevTools console
  - Document all errors, warnings, and failed network requests
  - Check for CORS, CSP, or module loading errors
  - **Acceptance**: List of all JavaScript errors documented
  - **Test**: Manual browser inspection
  - **Files**: N/A (diagnostic only)

- [x] **T007** [P] Verify CSS loading and grid layout styles
  - Check `app/assets/stylesheets/application.css` exists
  - Verify asset pipeline compilation works
  - Inspect grid container and photo elements in browser DevTools
  - Check if `position: relative` on container, `position: absolute` on photos
  - **Acceptance**: CSS loads, grid styles are applied
  - **Test**: `RAILS_ENV=production rails assets:precompile`
  - **Files**: `app/assets/stylesheets/application.css`

- [x] **T008** [P] Verify CSRF token in HTML meta tag
  - View page source of collage editor
  - Check for `<meta name="csrf-token" content="...">` in `<head>`
  - Verify `csrf_meta_tags` helper in layout
  - **Acceptance**: CSRF token present and accessible
  - **Test**: View source or `curl -s http://localhost:3000/collages/:guid | grep csrf-token`
  - **Files**: `app/views/layouts/application.html.erb`

- [x] **T009** [P] Check Turbo Drive configuration and interference
  - Verify Turbo is loaded: check `window.Turbo` in console
  - Check if Turbo Drive is enabled: `Turbo.session.drive`
  - Test if form submissions are being intercepted by Turbo
  - Check if page is cached by Turbo (causing stale state)
  - **Acceptance**: Turbo configuration documented
  - **Test**: Manual browser console inspection
  - **Files**: `app/views/collages/show.html.erb`, `app/views/layouts/application.html.erb`

- [x] **T010** [P] Test event communication between controllers
  - Add console.log statements in grid_controller.js `handlePhotoUploaded`
  - Add console.log in upload_controller.js before `dispatch('photoUploaded')`
  - Upload a photo and verify events fire
  - Check if event namespace matches (e.g., `upload:photoUploaded`)
  - **Acceptance**: Event flow documented, identify any broken communication
  - **Test**: Manual test with browser console open
  - **Files**: `app/javascript/controllers/grid_controller.js`, `app/javascript/controllers/upload_controller.js`

---

## Phase D2: Fix Tasks (Apply Targeted Fixes)

**IMPORTANT**: Only execute fixes for issues identified in Phase D1. Skip irrelevant fixes.

### Fix 1: Importmap/JavaScript Loading Issues

- [ ] **T011** Fix importmap configuration for Hotwire
  - Run `bin/importmap pin @hotwired/stimulus @hotwired/turbo-rails`
  - Verify pins in `config/importmap.rb`
  - Clear browser cache and test
  - **Acceptance**: Stimulus controllers load in browser
  - **Test**: Refresh page, check console for "controller connected" logs
  - **Files**: `config/importmap.rb`
  - **Depends on**: T003, T004

- [ ] **T012** Fix Stimulus controller registration in application.js
  - Verify `app/javascript/application.js` imports controllers correctly
  - Check `app/javascript/controllers/index.js` registers all controllers
  - Ensure controller file names match `data-controller` attributes
  - **Acceptance**: All controllers register properly
  - **Test**: Check `window.Stimulus.controllers` in console
  - **Files**: `app/javascript/application.js`, `app/javascript/controllers/index.js`
  - **Depends on**: T004

### Fix 2: CSRF Token Issues

- [ ] **T013** Add CSRF meta tags to layout if missing
  - Verify `<%= csrf_meta_tags %>` in `app/views/layouts/application.html.erb`
  - Ensure it's in the `<head>` section
  - **Acceptance**: CSRF token appears in page source
  - **Test**: View source, check for meta tag
  - **Files**: `app/views/layouts/application.html.erb`
  - **Depends on**: T008

- [ ] **T014** Verify CSRF token in Fetch requests
  - Check `csrfToken()` method exists in all controllers
  - Ensure `X-CSRF-Token` header is set in all Fetch calls
  - Test API calls return 200, not 422 Unprocessable Entity
  - **Acceptance**: API calls succeed with CSRF token
  - **Test**: Upload photo, check Network tab for successful request
  - **Files**: `app/javascript/controllers/upload_controller.js`, `app/javascript/controllers/grid_controller.js`, `app/javascript/controllers/photo_resize_controller.js`
  - **Depends on**: T005, T008

### Fix 3: Turbo Drive Interference

- [ ] **T015** Disable Turbo Drive on collage editor page if interfering
  - Add `data-turbo="false"` to `#content` div in `app/views/collages/show.html.erb`
  - Test if Stimulus controllers now work properly
  - Alternative: Set `Turbo.session.drive = false` globally if needed
  - **Acceptance**: JavaScript events fire correctly, no Turbo interception
  - **Test**: Upload photo, resize photo - verify functionality works
  - **Files**: `app/views/collages/show.html.erb`
  - **Depends on**: T009
  - **Note**: Only apply if T009 identifies Turbo as the issue

- [ ] **T016** Add Turbo lifecycle event listeners if Drive is enabled
  - Listen for `turbo:load` event to reinitialize controllers
  - Use `turbo:before-cache` to clean up state before page caching
  - Ensure controllers handle Turbo page transitions properly
  - **Acceptance**: Controllers work after Turbo navigation
  - **Test**: Navigate away from collage, then back - verify functionality
  - **Files**: `app/javascript/controllers/grid_controller.js`
  - **Depends on**: T009
  - **Note**: Only needed if keeping Turbo Drive enabled

### Fix 4: ObjectId JSON Serialization

- [ ] **T017** Ensure consistent ObjectId handling in controllers
  - Verify grid_controller.js handles both `{$oid: "..."}` and plain string IDs
  - Check photo_resize_controller.js extracts ID correctly
  - Add defensive checks for ObjectId format
  - **Acceptance**: Photos render correctly regardless of ID format
  - **Test**: Upload photo, verify it appears in grid with correct ID
  - **Files**: `app/javascript/controllers/grid_controller.js`, `app/javascript/controllers/photo_resize_controller.js`
  - **Depends on**: T005

- [ ] **T018** Standardize API JSON serialization if needed
  - Option A: Convert ObjectId to string in controller with `id.to_s`
  - Option B: Ensure frontend handles BSON extended JSON format
  - Update PhotosController and CollagesController to_json methods
  - **Acceptance**: Consistent ID format in all API responses
  - **Test**: `curl` API endpoints, verify ID format
  - **Files**: `app/controllers/photos_controller.rb`, `app/controllers/collages_controller.rb`
  - **Depends on**: T005
  - **Note**: Choose Option A (simpler) or B (preserves BSON) based on T005 findings

### Fix 5: CSS and Grid Layout

- [ ] **T019** Verify and fix grid layout CSS
  - Ensure `#collage_photos` has `position: relative`
  - Ensure `.photo` class has `position: absolute`, `overflow: hidden`
  - Check if Sass compilation works properly
  - Add any missing grid-specific styles
  - **Acceptance**: Photos position correctly in grid
  - **Test**: Upload photo, verify it's positioned absolutely
  - **Files**: `app/assets/stylesheets/application.css`
  - **Depends on**: T007

- [ ] **T020** Fix asset pipeline compilation if broken
  - Run `rake assets:precompile` and check for errors
  - Clear precompiled assets: `rake assets:clobber`
  - Verify Sass-rails gem is installed
  - Check `config/initializers/assets.rb` configuration
  - **Acceptance**: Assets compile without errors
  - **Test**: `RAILS_ENV=production rake assets:precompile`
  - **Files**: `config/initializers/assets.rb`, `app/assets/stylesheets/application.css`
  - **Depends on**: T007

### Fix 6: Event Communication

- [ ] **T021** Fix event dispatch/listener wiring if broken
  - Verify `dispatch()` uses correct event names
  - Ensure listeners use correct namespaced event names (e.g., `upload:photoUploaded`)
  - Check if events are dispatched on correct element (bubbling scope)
  - Verify event listeners are attached in `connect()` lifecycle
  - **Acceptance**: Events propagate correctly between controllers
  - **Test**: Upload photo, verify grid updates (check console logs)
  - **Files**: `app/javascript/controllers/upload_controller.js`, `app/javascript/controllers/grid_controller.js`, `app/javascript/controllers/photo_resize_controller.js`
  - **Depends on**: T010

---

## Phase D3: Verification Tasks (Confirm Fixes Work)

**CRITICAL**: Test each piece of functionality end-to-end to ensure complete restoration.

- [ ] **T022** [P] Test collage creation flow end-to-end
  - Navigate to homepage
  - Enter collage title and create
  - Verify redirect to collage editor
  - Check that both r_guid and rw_guid are generated
  - Verify title appears in header
  - **Acceptance**: Full collage creation works without errors
  - **Test**: Manual test via browser
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [ ] **T023** [P] Test photo upload via file picker
  - Click "choose files" button
  - Select an image file (JPG/PNG/GIF)
  - Verify upload progress displays
  - Verify photo appears in grid after upload
  - Check browser console for errors
  - **Acceptance**: File picker upload works completely
  - **Test**: Manual test with various image types
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [x] **T024** [P] Test photo upload via drag-and-drop
  - Drag image file onto collage editor page
  - Verify drag-over feedback appears
  - Verify upload starts automatically
  - Verify photo appears in grid after upload
  - **Acceptance**: Drag-and-drop upload works completely
  - **Test**: Manual test with drag-and-drop
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [x] **T025** [P] Test photo rendering in grid layout
  - Upload multiple photos
  - Verify photos are positioned left-to-right, top-to-bottom
  - Check aspect ratios are preserved
  - Verify no overlapping photos
  - Check grid extends vertically when full
  - **Acceptance**: Grid layout algorithm works correctly
  - **Test**: Upload 5-10 photos, inspect layout visually
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [x] **T026** [P] Test photo resize interaction
  - Hover near photo edge (within 10px)
  - Verify cursor changes to resize cursor
  - Click and drag edge to resize photo
  - Verify photo snaps to grid cells
  - Verify minimum 1x1 cell size enforced
  - **Acceptance**: Photo resize works smoothly
  - **Test**: Manual resize test on multiple photos
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [x] **T027** [P] Test grid re-flow after photo resize
  - Resize a photo in the middle of grid
  - Verify other photos reposition correctly
  - Check that no photos overlap after re-flow
  - Verify layout fills left-to-right, top-to-bottom
  - **Acceptance**: Grid re-flow algorithm works correctly
  - **Test**: Resize photos and observe grid behavior
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [ ] **T028** Test duplicate photo detection
  - Upload same photo twice
  - Verify first upload shows warning dialog
  - Upload same photo third time
  - Verify silent deduplication (no second warning)
  - **Acceptance**: Duplicate detection works per session (FR-017 to FR-019)
  - **Test**: Upload same image multiple times
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [ ] **T029** Test read-only vs read-write access
  - Create collage, copy read-only URL
  - Open read-only URL in incognito window
  - Verify "choose files" button is hidden
  - Verify resize handles don't work
  - Attempt API call with r_guid, verify 403 Forbidden
  - **Acceptance**: Access control enforced (FR-041 to FR-046)
  - **Test**: Test both URL types
  - **Files**: N/A (verification only)
  - **Depends on**: All Phase D2 fixes

- [ ] **T030** Run existing RSpec test suite
  - Run `bundle exec rspec` for model and request specs
  - Verify no regressions introduced
  - Check coverage report
  - Fix any broken tests
  - **Acceptance**: All existing tests pass
  - **Test**: `bundle exec rspec`
  - **Files**: `spec/**/*_spec.rb`
  - **Depends on**: All Phase D2 fixes

- [ ] **T031** Run system/integration tests if available
  - Run `bundle exec rspec spec/system` for Capybara tests
  - Test full user flows end-to-end
  - Verify JavaScript interactions work in headless browser
  - **Acceptance**: System tests pass
  - **Test**: `bundle exec rspec spec/system`
  - **Files**: `spec/system/**/*_spec.rb`
  - **Depends on**: All Phase D2 fixes

---

## Phase D4: Performance & Polish

- [ ] **T032** [P] Verify performance targets met
  - Run Lighthouse audit on collage editor page
  - Verify page load <100ms (NFR-001)
  - Test drag-and-drop runs at 60fps
  - Check progressive image loading works (NFR-002)
  - **Acceptance**: Performance targets from spec met
  - **Test**: `lighthouse http://localhost:3000/collages/:guid --view`
  - **Files**: N/A (verification only)
  - **Depends on**: T022-T031

- [ ] **T033** [P] Remove diagnostic console.log statements
  - Remove temporary logging added in T010
  - Clean up any debug code from fixes
  - Ensure production-ready console output
  - **Acceptance**: No debug logs in production code
  - **Test**: Grep for console.log in controllers
  - **Files**: `app/javascript/controllers/*.js`
  - **Depends on**: T022-T031

- [ ] **T034** Document fixes and root causes
  - Update `specs/001-awesome-use-the/research.md` with findings
  - Document which fixes were needed (T011-T021)
  - Add notes for future reference
  - **Acceptance**: Research document updated with resolution
  - **Test**: Manual review
  - **Files**: `specs/001-awesome-use-the/research.md`
  - **Depends on**: T022-T031

- [ ] **T035** Run quickstart.md validation scenarios
  - Execute all manual test scenarios from quickstart.md
  - Verify all 53 functional requirements work
  - Document any remaining issues
  - **Acceptance**: Quickstart validation complete
  - **Test**: Follow steps in `specs/001-awesome-use-the/quickstart.md`
  - **Files**: N/A (verification only)
  - **Depends on**: T022-T033

---

## Dependencies

**Phase D1** (Diagnostic):
- All D1 tasks (T001-T010) can run in parallel [P]
- Must complete ALL D1 tasks before proceeding to D2

**Phase D2** (Fixes):
- T011-T012 (Importmap): Sequential, depend on T003-T004
- T013-T014 (CSRF): Sequential, depend on T008, T005
- T015-T016 (Turbo): Sequential, depend on T009 (mutually exclusive - choose one)
- T017-T018 (ObjectId): Sequential, depend on T005
- T019-T020 (CSS): Sequential, depend on T007
- T021 (Events): Depends on T010
- Only execute fixes for issues found in D1

**Phase D3** (Verification):
- All D3 tasks (T022-T031) depend on completing relevant D2 fixes
- T022-T027 can run in parallel [P] as manual tests
- T028-T029 sequential (specific scenarios)
- T030-T031 sequential (test suites)

**Phase D4** (Polish):
- All D4 tasks (T032-T035) depend on D3 completion
- T032-T033 can run in parallel [P]

## Parallel Execution Examples

### Diagnostic Phase (All Parallel)
```bash
# Launch all diagnostic tasks together
# Check server, MongoDB, importmap, Stimulus, API, console, CSS, CSRF, Turbo, events
# Recommended: Run each in separate terminal or note results systematically
```

### Verification Phase (Independent Tests)
```bash
# After fixes applied, test functionality in parallel
# T022: Collage creation
# T023: File picker upload
# T024: Drag-and-drop upload
# T025: Grid rendering
# T026: Photo resize
# T027: Grid re-flow
# Each can be tested independently in different browser windows
```

## Task Execution Notes

1. **Start with diagnostics**: Complete ALL T001-T010 to understand issues
2. **Apply only needed fixes**: Skip fix tasks for non-issues (e.g., if Turbo isn't interfering, skip T015-T016)
3. **Test incrementally**: After each fix, verify it resolves the specific issue
4. **Document findings**: Note which fixes were needed in T034
5. **Full verification**: Run complete test suite (T030-T031) before declaring done

## Validation Checklist

- [x] All Phase D1 tasks provide clear diagnostic steps
- [x] All Phase D2 tasks specify exact file paths
- [x] All Phase D2 tasks have dependencies on relevant D1 diagnostics
- [x] Phase D3 tasks cover all main user flows (FR-001 to FR-053)
- [x] Parallel tasks [P] truly independent (different files or read-only)
- [x] Sequential tasks have clear dependency chain
- [x] Tasks match research.md diagnostic hypotheses
- [x] Tasks align with quickstart.md validation scenarios

## Success Criteria

Frontend functionality is considered "working again" when:
1. ✅ Stimulus controllers load and connect
2. ✅ Photo upload works (file picker + drag-and-drop)
3. ✅ Photos render in grid with correct layout
4. ✅ Photo resize works via edge dragging
5. ✅ Grid re-flows correctly after resize
6. ✅ All API endpoints return correct JSON
7. ✅ Events communicate between controllers
8. ✅ Existing test suite passes
9. ✅ Performance targets met (NFR-001, NFR-002)
10. ✅ All 53 functional requirements verified via quickstart.md
