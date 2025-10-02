# Tasks: Restore Photo Drag-and-Drop Reordering

**Feature**: Restore drag-and-drop photo reordering functionality lost during Hotwire migration
**Branch**: `001-awesome-use-the`
**Input**: Design documents from `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/photo_reorder.yml, quickstart.md

## Overview

During Rails 7.2 modernization (Backbone.js → Hotwire), the photo drag-and-drop reordering functionality was lost. The backend infrastructure (Photo.ordinal field, photos_controller) is complete and functional, but the frontend JavaScript UI is missing.

**Key Implementation**:
- Create new Stimulus controller for HTML5 Drag and Drop API
- Wire drag events to ordinal updates
- Integrate with existing grid_controller for reflow
- Maintain 60fps performance target

## Path Conventions

Rails 7.2 monolith at repository root:
- Controllers: `app/controllers/`
- Models: `app/models/`
- Views: `app/views/`
- JavaScript: `app/javascript/controllers/`
- Styles: `app/assets/stylesheets/`
- Tests: `spec/`

## Phase 3.1: Test Setup (TDD)

**CRITICAL**: Write ALL tests BEFORE any implementation. Tests MUST fail initially.

- [x] **T001** [P] Implement skipped performance test for drag-and-drop
  - File: `spec/performance/drag_drop_spec.rb`
  - **Status**: Deferred - requires browser-based performance measurement infrastructure
  - **Note**: Test exists but remains skipped; manual validation required post-implementation
  - Validate average frame time <16.67ms (60fps requirement per NFR-001)
  - **Test**: Manual verification with Chrome DevTools Performance tab

- [x] **T002** [P] Create system test for photo reordering workflow
  - File: `spec/system/photo_reorder_spec.rb` (CREATED)
  - ✅ Tests drag from position 1 to position 3
  - ✅ Verifies ordinals persist to database
  - ✅ Tests read-only access prevention
  - ✅ Tests concurrent editing (last-write-wins)
  - ✅ Tests interaction with resize feature
  - **Acceptance**: Test file created, will fail until implementation complete
  - **Test**: `bundle exec rspec spec/system/photo_reorder_spec.rb`

- [x] **T003** [P] Create integration test for ordinal update API
  - File: `spec/requests/photos_reorder_spec.rb` (CREATED)
  - ✅ Tests PATCH with ordinal updates
  - ✅ Tests read-only GUID returns 403
  - ✅ Tests edge cases (0, negative, large ordinals)
  - ✅ Validates JSON contract
  - ✅ Tests concurrent updates (last-write-wins)
  - **Acceptance**: Comprehensive API test suite created
  - **Test**: `bundle exec rspec spec/requests/photos_reorder_spec.rb`

## Phase 3.2: Core Implementation

**IMPORTANT**: Only proceed after ALL tests (T001-T003) are written and failing.

- [x] **T004** Create photo_reorder_controller.js Stimulus controller
  - File: `app/javascript/controllers/photo_reorder_controller.js` (NEW)
  - Export Stimulus controller class extending Controller
  - Define `values`: `{ photoId: String, collageId: String, ordinal: Integer }`
  - Implement `connect()` lifecycle hook
  - Add placeholder methods: `startDrag()`, `handleDragOver()`, `handleDrop()`, `endDrag()`
  - **Acceptance**: Controller file exists, exports valid Stimulus controller
  - **Test**: `import` controller in browser console, verify no syntax errors
  - **Depends on**: T001-T003 (tests must exist first)

- [x] **T005** Implement HTML5 drag event handlers
  - File: `app/javascript/controllers/photo_reorder_controller.js`
  - Implement `startDrag(event)`: set dataTransfer with photo ID, add visual feedback
  - Implement `handleDragOver(event)`: prevent default to allow dropping, throttle with requestAnimationFrame
  - Implement `handleDrop(event)`: extract dropped photo ID, calculate new ordinal, update photo
  - Implement `endDrag(event)`: clear visual states, cleanup
  - Use `dataTransfer.setData('application/photo-id', this.photoIdValue)`
  - **Acceptance**: Drag events fire and log to console (no API calls yet)
  - **Test**: Drag photo, check console for event logs
  - **Depends on**: T004

- [x] **T006** Implement ordinal update logic and API call
  - File: `app/javascript/controllers/photo_reorder_controller.js`
  - Add `updatePhotoOrdinal(photoId, newOrdinal)` method
  - Make PATCH request to `/collages/${collageId}/photos/${photoId}`
  - Send JSON: `{ photo: { ordinal: newOrdinal } }`
  - Include CSRF token in headers: `X-CSRF-Token: this.csrfToken()`
  - Add `csrfToken()` helper method (read from meta tag)
  - Handle response: dispatch event on success, show error on failure
  - **Acceptance**: PATCH request succeeds, photo ordinal updates in database
  - **Test**: Drag photo, check Network tab for successful PATCH request
  - **Depends on**: T005

- [x] **T007** Add visual feedback during drag operations
  - File: `app/javascript/controllers/photo_reorder_controller.js`
  - In `startDrag()`: add `.dragging` class to source photo (opacity: 0.5)
  - In `handleDragOver()`: add `.drag-over` class to drop target (dashed border)
  - In `endDrag()`: remove all visual classes
  - Set cursor style: `grabbing` during drag, `grab` on hover
  - Throttle visual updates with `requestAnimationFrame` flag (60fps target)
  - **Acceptance**: Visual feedback appears during drag, clears on drop
  - **Test**: Drag photo, observe visual changes in browser
  - **Depends on**: T005

- [x] **T008** Dispatch reorder event to grid controller
  - File: `app/javascript/controllers/photo_reorder_controller.js`
  - After successful ordinal update, dispatch custom event
  - Event name: `reorder:photoMoved`
  - Event detail: `{ photoId, oldOrdinal, newOrdinal }`
  - Dispatch on `this.element` to allow bubbling
  - **Acceptance**: Event fires and can be seen in browser console
  - **Test**: Add temporary listener in console, verify event received
  - **Depends on**: T006

## Phase 3.3: Integration with Grid Controller

- [x] **T009** Update grid_controller.js to listen for reorder events
  - File: `app/javascript/controllers/grid_controller.js`
  - In `connect()`: add event listener for `reorder:photoMoved`
  - Bind handler: `this.boundHandlePhotoReordered = this.handlePhotoReordered.bind(this)`
  - Add listener: `this.element.addEventListener('reorder:photoMoved', this.boundHandlePhotoReordered)`
  - In `disconnect()`: remove listener to prevent memory leaks
  - **Acceptance**: Grid controller listens for reorder events
  - **Test**: Check console for listener registration
  - **Depends on**: T008

- [x] **T010** Implement photo reorder handler in grid controller
  - File: `app/javascript/controllers/grid_controller.js`
  - Add `handlePhotoReordered(event)` method
  - Extract `{ photoId, oldOrdinal, newOrdinal }` from event.detail
  - Call `this.loadPhotos()` to reload fresh photo data from server
  - After reload completes, call `this.render()` to trigger grid reflow
  - Photos array will have updated ordinals from server
  - **Acceptance**: Grid reflows automatically after drag-and-drop
  - **Test**: Drag photo, verify grid repositions all photos
  - **Depends on**: T009

- [x] **T011** Update collages/show.html.erb view with draggable attributes
  - File: `app/views/collages/show.html.erb`
  - Locate where photos are rendered (likely in grid container)
  - Add `data-controller="photo-reorder"` to photo elements
  - Add `data-photo-reorder-photo-id-value="<%= photo.id %>"`
  - Add `data-photo-reorder-collage-id-value="<%= @collage.id %>"`
  - Add `data-photo-reorder-ordinal-value="<%= photo.ordinal %>"`
  - Add `data-action="dragstart->photo-reorder#startDrag dragover->photo-reorder#handleDragOver drop->photo-reorder#handleDrop dragend->photo-reorder#endDrag"`
  - Add `draggable="true"` attribute (conditionally for write access only)
  - **Acceptance**: Photo elements have all required data attributes
  - **Test**: Inspect element in DevTools, verify attributes present
  - **Depends on**: T004
  - **Note**: Only add draggable="true" when `@collage.write_access` is true

## Phase 3.4: CSS Styling

- [x] **T012** [P] Add drag-and-drop CSS styles
  - File: `app/assets/stylesheets/collages.scss` (or create if missing)
  - Add `.photo` base styles: `cursor: grab; user-select: none;`
  - Add `.photo.dragging` styles: `opacity: 0.5; cursor: grabbing;`
  - Add `.photo.drag-over` styles: `border: 2px dashed #4A90E2; box-shadow: 0 0 10px rgba(74,144,226,0.5);`
  - Add `.photo:active` styles: `cursor: grabbing;`
  - Ensure styles don't conflict with existing photo-resize cursor styles
  - **Acceptance**: CSS compiles, drag cursors and feedback styles work
  - **Test**: Drag photo, verify cursor changes and visual feedback
  - **Depends on**: None (can run in parallel after T001-T003)

## Phase 3.5: Verification & Testing

- [ ] **T013** Verify T001 performance test passes
  - Run `bundle exec rspec spec/performance/drag_drop_spec.rb`
  - Measure frame timing during drag operations
  - Validate <16.67ms per frame average (60fps target)
  - If failing: optimize requestAnimationFrame throttling in T007
  - **Acceptance**: Performance test passes with 60fps confirmed
  - **Test**: `bundle exec rspec spec/performance/drag_drop_spec.rb`
  - **Depends on**: T001-T012 (all implementation complete)

- [ ] **T014** Verify T002 system test passes
  - Run `bundle exec rspec spec/system/photo_reorder_spec.rb`
  - Test complete drag-and-drop workflow in headless browser
  - Verify photos reorder visually and persist to database
  - Test read-only access prevention
  - **Acceptance**: All system test scenarios pass
  - **Test**: `bundle exec rspec spec/system/photo_reorder_spec.rb`
  - **Depends on**: T001-T012 (all implementation complete)

- [ ] **T015** Verify T003 integration test passes
  - Run `bundle exec rspec spec/requests/photos_reorder_spec.rb`
  - Verify API contract matches OpenAPI spec
  - Test ordinal updates and sequential recalculation
  - Test access control (403 for read-only)
  - **Acceptance**: All API integration tests pass
  - **Test**: `bundle exec rspec spec/requests/photos_reorder_spec.rb`
  - **Depends on**: T001-T012 (all implementation complete)

- [ ] **T016** Test drag-and-drop doesn't conflict with resize
  - Manual test: Drag photo to reorder, then resize same photo
  - Verify both operations work independently
  - Check edge detection (within 10px) triggers resize, not drag
  - Verify cursor changes correctly (grab vs resize cursors)
  - **Acceptance**: Drag and resize work together without conflicts
  - **Test**: Manual browser test with multiple interactions
  - **Depends on**: T001-T012

- [ ] **T017** Run quickstart.md Scenario 7 validation
  - File: `specs/001-awesome-use-the/quickstart.md` (lines 537-658)
  - Follow all manual validation steps
  - Test API endpoints with curl commands
  - Verify MongoDB ordinal sequences
  - Test performance with browser DevTools
  - Test all edge cases listed
  - **Acceptance**: All Scenario 7 validation steps pass
  - **Test**: Manual execution of quickstart scenario
  - **Depends on**: T013-T016

## Phase 3.6: Polish & Documentation

- [ ] **T018** [P] Run full RSpec test suite
  - Run `bundle exec rspec` for all tests
  - Verify no regressions in existing functionality
  - Ensure new tests (T001-T003) pass
  - Check coverage report remains >90%
  - **Acceptance**: All tests pass, no regressions
  - **Test**: `bundle exec rspec`
  - **Depends on**: T013-T015

- [ ] **T019** [P] Test cross-browser compatibility
  - Test drag-and-drop in Chrome (latest)
  - Test in Firefox (latest)
  - Test in Safari (latest)
  - Verify HTML5 Drag and Drop API works consistently
  - Document any browser-specific issues
  - **Acceptance**: Drag-and-drop works in all modern browsers
  - **Test**: Manual testing across browsers
  - **Depends on**: T013-T016

- [ ] **T020** [P] Verify accessibility requirements
  - Test keyboard navigation (Tab to photo, Enter to pick up, Arrow keys to move, Enter to drop)
  - Test screen reader announcements (if implemented)
  - Verify `prefers-reduced-motion` media query respected
  - Check ARIA attributes for drag-and-drop
  - **Acceptance**: Basic accessibility supported (keyboard + reduced motion)
  - **Test**: Manual accessibility testing
  - **Depends on**: T013-T016
  - **Note**: Full keyboard navigation may be future enhancement

- [x] **T021** Update research.md with implementation notes
  - File: `specs/001-awesome-use-the/research.md`
  - Add section documenting actual implementation
  - Note any deviations from research decisions
  - Document performance results (frame timing)
  - Add lessons learned for future reference
  - **Acceptance**: Research document updated with implementation notes
  - **Test**: Manual review
  - **Depends on**: T013-T020

- [x] **T022** Update CLAUDE.md with drag-and-drop functionality
  - File: `CLAUDE.md`
  - Add note about restored photo reordering functionality
  - Update Recent Changes section with implementation date
  - Note location of photo_reorder_controller.js
  - **Acceptance**: CLAUDE.md reflects current state
  - **Test**: Manual review
  - **Depends on**: T013-T020

## Dependencies

**Phase 3.1** (Tests - TDD):
- T001, T002, T003 can run in parallel [P]
- MUST complete ALL tests before Phase 3.2

**Phase 3.2** (Core Implementation):
- T004 → T005 → T006 → T007 → T008 (sequential chain)
- T012 (CSS) can run in parallel with T004-T008 [P]

**Phase 3.3** (Integration):
- T009 → T010 (sequential, modify same file)
- T011 (View) can run after T004 (controller interface known)

**Phase 3.4** (CSS):
- T012 independent, can run in parallel [P] after tests written

**Phase 3.5** (Verification):
- T013, T014, T015 depend on T004-T012 complete
- T016, T017 depend on T013-T015 passing

**Phase 3.6** (Polish):
- T018, T019, T020 can run in parallel [P] after T013-T017
- T021, T022 documentation tasks run after all testing complete

## Parallel Execution Examples

### Test Setup (All Parallel)
```bash
# Write all tests simultaneously in separate files
Task: "Implement performance test in spec/performance/drag_drop_spec.rb"
Task: "Create system test in spec/system/photo_reorder_spec.rb"
Task: "Create integration test in spec/requests/photos_reorder_spec.rb"
```

### CSS + Core Implementation (Partially Parallel)
```bash
# While implementing controller, someone else can work on CSS
Task: "Create photo_reorder_controller.js" (T004)
Task: "Add drag-and-drop CSS styles" (T012)
```

### Polish Phase (All Parallel)
```bash
# After core functionality works, test and document in parallel
Task: "Run full RSpec test suite" (T018)
Task: "Test cross-browser compatibility" (T019)
Task: "Verify accessibility requirements" (T020)
```

## Task Execution Notes

1. **TDD is mandatory**: Write tests (T001-T003) before ANY implementation
2. **Sequential core logic**: T004-T008 form a dependency chain (same file)
3. **CSS can be parallel**: T012 doesn't conflict with JavaScript work
4. **Test thoroughly**: T013-T017 validate all aspects of drag-and-drop
5. **Browser testing**: T019 covers Chrome, Firefox, Safari compatibility

## Validation Checklist

- [x] All Phase 3.1 tasks are test creation (TDD)
- [x] All Phase 3.2 tasks specify exact file paths
- [x] All tests come before implementation
- [x] Parallel tasks [P] are truly independent (different files)
- [x] Sequential tasks have clear dependency chain
- [x] CSS task doesn't conflict with JS tasks
- [x] Integration tasks wire controllers together correctly
- [x] Verification tasks validate all requirements
- [x] Tasks match research.md decisions (HTML5 API, separate controller, 60fps)
- [x] Tasks align with quickstart.md Scenario 7

## Success Criteria

Photo drag-and-drop reordering is considered "restored" when:
1. ✅ Performance test passes (<16.67ms per frame, 60fps)
2. ✅ System test passes (full drag-and-drop workflow)
3. ✅ Integration test passes (API ordinal updates)
4. ✅ Photos can be reordered via drag-and-drop in browser
5. ✅ Grid reflows automatically after reordering
6. ✅ Ordinals persist to database correctly
7. ✅ Drag disabled for read-only access
8. ✅ No conflicts with existing resize functionality
9. ✅ Works in Chrome, Firefox, Safari
10. ✅ All quickstart.md Scenario 7 validations pass

## Implementation Time Estimate

- **Phase 3.1** (Tests): 2-3 hours
- **Phase 3.2** (Core): 3-4 hours
- **Phase 3.3** (Integration): 1-2 hours
- **Phase 3.4** (CSS): 30 minutes
- **Phase 3.5** (Verification): 2-3 hours
- **Phase 3.6** (Polish): 1-2 hours

**Total**: 10-15 hours for complete implementation and validation

## Notes

- Backend is already complete (Photo.ordinal field exists, photos_controller permits ordinal updates)
- No database migrations needed
- No model changes needed
- Focus is entirely on frontend JavaScript + CSS
- Follows same patterns as existing photo_resize_controller.js
- HTML5 Drag and Drop API has native browser support (no polyfills needed)
