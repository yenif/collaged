# Test Baseline - Collaged Application

**Date**: 2025-09-30
**Purpose**: Establish behavioral baseline before Rails 3.2 → 7.2 modernization

## Environment

- **Ruby Version**: 3.4.4 (managed by mise)
- **Rails Version**: 3.2.14 (from Gemfile)
- **Test Framework**: RSpec 2.14 + Cucumber 0.4
- **Database**: MongoDB with Mongoid 3.1.4

## Test Suite Status

### Execution Attempt

**Status**: ❌ Cannot execute tests due to corrupted gem cache

**Error**:
```
Bundler::GemspecError: Could not read gem at /Library/Ruby/Gems/2.6.0/cache/rack-cache-1.2.gem.
It may be corrupted.
```

**Root Cause**: System Ruby gem cache corruption, requires sudo for system-level gems which is not available in automated environment.

### Test Structure Analysis (Static)

#### RSpec Tests

**Location**: `/Users/bf/Code/claude/collaged/spec/`

**Discovered Test Files**:
1. `spec/models/collage_spec.rb` - Placeholder (pending tests only)
2. `spec/models/photo_spec.rb` - 2 dimension calculation tests
3. `spec/controllers/collages_controller_spec.rb` - Controller tests
4. `spec/controllers/root_controller_spec.rb` - Root controller tests
5. `spec/helpers/templater_spec.rb` - Helper tests

**Existing Photo Model Tests** (spec/models/photo_spec.rb):
- ✓ Calculates correct default dimensions for tall images (100:1 aspect)
- ✓ Calculates correct default dimensions for wide images (1:100 aspect)

**Test Coverage**:
- Photo dimension calculation: ✓ Partial (2 tests)
- Collage GUID generation: ❌ No tests
- Collage find_by_guid logic: ❌ No tests
- Photo grid layout: ❌ No tests
- Image upload: ❌ No tests
- Access control: ❌ No tests

#### Cucumber Tests

**Location**: `/Users/bf/Code/claude/collaged/features/`

**Discovered Feature Files**:
1. `features/root.feature` - Homepage collage creation (@javascript tag)

**Cucumber Scenarios**:
- Scenario: "I can create a collage from the homepage" (@javascript)
  - Validates homepage presence
  - Validates "Create a Collaged" button
  - Validates "Title" field

#### Coverage Analysis

**SimpleCov**: Not configured (no coverage/ directory found)

**Estimated Coverage** (from static analysis):
- Models: ~10% (basic photo dimensions only)
- Controllers: Unknown (cannot inspect without running)
- Views: 0% (no view tests found)
- JavaScript: 0% (no JS tests found)

### Critical Gaps Identified

The following behaviors have **zero test coverage** and must be characterized:

1. **Collage Model**:
   - GUID generation (UUIDTools.UUID.random_create)
   - Collision detection in initialize_guids
   - find_by_guid with r_guid vs rw_guid
   - write_access flag propagation
   - to_param behavior (returns rw_guid when write_access true)

2. **Photo Model**:
   - Prime factorization for grid dimensions
   - Aspect ratio preservation algorithm
   - SHA1 image_hash generation
   - ordinal sorting
   - size = width × height constraint enforcement
   - CarrierWave upload integration

3. **Frontend** (Backbone.js + jQuery + Plupload):
   - No test coverage for any JavaScript
   - Routes: routers/app.js.coffee
   - Models: models/collage.js.coffee, models/photo.js.coffee
   - Plupload runtime selection (HTML5/Flash/Silverlight/BrowserPlus/Gears/HTML4)
   - Drag-and-drop resize interactions
   - Multi-file upload with progress tracking

4. **Integration**:
   - Full collage creation flow
   - Photo upload with duplicate detection
   - Grid layout and re-flow
   - Access control enforcement

### Recommendations for Characterization Phase

**Priority 1** (P0 - Required before any changes):
- ✅ T002: Create Collage model characterization tests
- ✅ T003: Expand Photo model characterization tests
- ✅ T004: Document JavaScript behavior patterns
- ✅ T005: Export MongoDB schema
- ✅ T006: Establish performance baseline

**Priority 2** (P4 - Test infrastructure modernization):
- Upgrade RSpec 2.14 → 6.1
- Upgrade Capybara 0.4 → 3.x
- Add SimpleCov for coverage reporting
- Migrate Cucumber → RSpec system tests

### Test Execution Requirements

To enable test execution, one of the following is required:

**Option 1**: Fix system gem cache
```bash
gem cleanup
bundle clean --force
bundle install
```

**Option 2**: Use project-local gem installation
```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

**Option 3**: Use Docker environment (recommended for modernization)
```bash
docker-compose run app bundle install
docker-compose run app bundle exec rspec
```

## Baseline Metrics

**Test Counts** (Static Analysis):
- Total spec files: 5
- Total feature files: 1
- Estimated test count: 2-10 RSpec examples + 1 Cucumber scenario

**Expected Coverage**: <15% (very low baseline)

**Test Execution Time**: Unknown (cannot run)

**Flaky Tests**: Unknown (cannot run)

## Next Steps

1. ✅ Proceed with T002-T006 (characterization tests can be written without running)
2. ✅ Document behavior from code analysis
3. ⏳ Fix bundle install issues before Phase P1 (Rails upgrade)
4. ⏳ Establish CI pipeline for automated test execution

---

**Note**: This baseline documents the **intended** behavior based on code analysis. Actual runtime behavior validation requires resolving the bundle installation issue.
