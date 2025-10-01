# Performance Baseline - Collaged Application

**Date**: 2025-09-30
**Purpose**: Establish performance metrics before Rails 3.2 → 7.2 modernization
**Status**: Documented from code analysis (cannot run live tests)

## Non-Functional Requirements (Target Metrics)

From `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/plan.md`:

| Metric | Target | Source |
|--------|--------|--------|
| Page Load (Structure) | <100ms | NFR-001 |
| Drag-and-Drop FPS | 60fps | NFR-002 |
| Image Upload Duration | Baseline for 10MB file | NFR-003 |
| Memory Usage | Baseline | NFR-004 |

## Expected Performance Characteristics (2013 Baseline)

### 1. Page Load Times

**Target**: <100ms for page structure (excludes image loading)

**Measurement Method**:
- Time To Interactive (TTI) via Lighthouse
- Excludes image/asset loading (measures HTML structure only)

**Legacy Stack Impact**:
- **Rails 3.2.14**: Known for slower boot and request times vs modern Rails
- **Asset Pipeline**: Sprockets asset compilation (no minification in dev)
- **Backbone.js**: Client-side rendering adds overhead
- **MongoDB**: Embedded photos mean single query for full collage

**Expected Bottlenecks**:
1. Asset compilation (multiple JS/CSS files)
2. Backbone app initialization (multiple models, views, routers)
3. Plupload library size (multiple runtime files)
4. Underscore template compilation

**Lighthouse Command**:
```bash
lighthouse http://localhost:3000/collages/[GUID] \
  --output html \
  --output-path docs/characterization/lighthouse-baseline.html \
  --only-categories=performance
```

**Key Metrics to Capture**:
- First Contentful Paint (FCP)
- Time to Interactive (TTI)
- Total Blocking Time (TBT)
- Cumulative Layout Shift (CLS)
- Largest Contentful Paint (LCP)

### 2. Drag-and-Drop FPS

**Target**: 60fps (16.67ms frame budget)

**Measurement Method**:
- Chrome DevTools Performance panel
- Record timeline during photo resize
- Analyze frame rate and dropped frames

**Current Implementation Risk Factors**:

```javascript
// From collage_photos_view.js.coffee.erb
$(document).mousemove (e) =>
  e.preventDefault()
  x = Math.round((e.pageX - origin.left)/grid_x_inc)
  y = Math.round((e.pageY - origin.top)/grid_y_inc)

  if x != view.model.width() || y != view.model.height()
    view.model.width(x)
    view.model.height(y)
    @render()  // FULL GRID RE-RENDER ON EVERY MOUSEMOVE!
```

**Performance Issues Identified**:
1. **No throttling/debouncing**: Every mousemove triggers render
2. **Full grid reflow**: Entire collection re-rendered (O(n) where n = photo count)
3. **DOM manipulation**: Detaches and re-appends all photo views
4. **Layout recalculation**: Browser recalculates layout for entire grid
5. **No requestAnimationFrame**: Not optimized for animation loop

**Expected Performance**:
- **1-5 photos**: Likely 60fps
- **10-20 photos**: Likely 30-50fps (dropped frames)
- **50+ photos**: Likely <30fps (severe stuttering)

**Measurement Steps**:
1. Open Chrome DevTools → Performance tab
2. Start recording
3. Perform drag-to-resize on photo
4. Stop recording
5. Analyze:
   - Frame rate (green bars should be above 60fps line)
   - Long tasks (yellow/red bars indicate dropped frames)
   - Scripting time (should be <16.67ms per frame)

**Test Scenarios**:
- Resize with 5 photos
- Resize with 20 photos
- Resize with 50 photos
- Measure FPS degradation as photo count increases

### 3. Image Upload Duration

**Target**: Establish baseline for 10MB file

**Measurement Method**:
- Measure from FilesAdded event to FileUploaded event
- Exclude network time (focus on processing overhead)

**Current Upload Flow**:

```javascript
// From collage_show.js.coffee.erb
@uploader.bind('FilesAdded', (up, files) =>
  up.start()  // Auto-start upload
)

@uploader.bind('UploadProgress', (up, file) =>
  $('#' + file.id + " b").html(file.percent + "%")
)

@uploader.bind('FileUploaded', (up, file, response) =>
  this.model.photos().add($.parseJSON(response.response))
  $('#' + file.id + " b").html("100%")
)
```

**Timing Components**:
1. **Client-side**:
   - File selection/validation
   - Plupload runtime initialization
   - FormData preparation
   - Progress callback overhead
2. **Network**:
   - Upload to server (varies by connection)
3. **Server-side** (Rails 3.2 + CarrierWave):
   - Request parsing (multipart/form-data)
   - Image validation
   - SHA1 hash calculation (for duplicate detection)
   - CarrierWave processing (store file)
   - Thumbnail generation (if configured)
   - Database save (Mongoid + MongoDB)
   - JSON response generation

**Baseline Test**:
- Upload 1MB file: ~X seconds
- Upload 5MB file: ~X seconds
- Upload 10MB file: ~X seconds (max allowed)
- Upload 11MB file: Should reject with HTTP 413

**Expected Performance**:
- **Client overhead**: <100ms (Plupload is optimized)
- **Network**: Depends on bandwidth (not measured)
- **Server overhead**: 200-500ms for 10MB file
  - SHA1 hash: ~50ms
  - CarrierWave store: ~100ms
  - Image metadata extraction: ~50ms
  - Mongoid save: ~50ms
  - Thumbnail generation: ~200ms (if enabled)

**Measurement Command**:
```javascript
// Browser console timing
var start = performance.now();
// Upload file via Plupload
// On FileUploaded callback:
var end = performance.now();
console.log('Upload duration:', end - start, 'ms');
```

### 4. Memory Usage

**Target**: Establish baseline

**Measurement Method**:
- Chrome DevTools → Memory tab
- Take heap snapshot before/after operations

**Memory Concerns**:

**JavaScript Heap**:
- Backbone models/collections/views
- Circular references (`model.view = this`, `collection.view = this`)
- Event listeners (potential memory leaks if not unbound)
- Plupload queue (stores file data in memory)
- Image data URLs (if used for preview)

**DOM**:
- All photos rendered in DOM (no virtualization)
- Large collages (50+ photos) = 50+ DOM elements
- Each photo has event listeners for resize/move

**Expected Memory Usage**:
- **Empty page**: ~10-20MB heap
- **5 photos**: ~30-40MB heap
- **20 photos**: ~80-100MB heap
- **50 photos**: ~200-300MB heap

**Memory Leak Risks**:
1. **Backbone event bindings**: Not properly unbound on view removal
2. **jQuery event listeners**: May persist after view destruction
3. **Plupload runtime**: Flash/Silverlight may leak memory
4. **Circular references**: `model.view` and `view.model` prevent garbage collection

**Measurement Steps**:
1. Open Chrome DevTools → Memory tab
2. Take heap snapshot (baseline)
3. Create collage + upload 20 photos
4. Take heap snapshot (loaded)
5. Navigate away from page
6. Force garbage collection
7. Take heap snapshot (after GC)
8. Compare: If heap didn't shrink, there's a memory leak

## Performance Test Suite (Phase P4)

**File**: `spec/performance/` (to be created in T049)

**Test Cases**:

### 1. Page Load Performance Test
```ruby
# spec/performance/page_load_spec.rb
require 'rails_helper'

RSpec.describe "Page Load Performance", type: :performance do
  it "loads collage show page in <100ms (structure only)" do
    collage = create(:collage)

    start = Time.now
    visit collage_path(collage.r_guid)
    time_to_interactive = (Time.now - start) * 1000  # Convert to ms

    expect(time_to_interactive).to be < 100
  end
end
```

### 2. Drag-and-Drop FPS Test
```ruby
# spec/performance/drag_drop_spec.rb
require 'rails_helper'

RSpec.describe "Drag-and-Drop Performance", type: :performance do
  it "maintains 60fps during photo resize" do
    collage = create(:collage_with_20_photos)
    visit collage_path(collage.rw_guid)

    # Use Chrome Performance API via JavaScript
    frame_times = page.evaluate_script(<<-JS)
      const times = [];
      let lastFrame = performance.now();

      // Simulate resize for 1 second
      const interval = setInterval(() => {
        const now = performance.now();
        times.push(now - lastFrame);
        lastFrame = now;
      }, 0);

      setTimeout(() => clearInterval(interval), 1000);

      times;
    JS

    # Calculate average FPS
    avg_frame_time = frame_times.sum / frame_times.length
    fps = 1000 / avg_frame_time

    expect(fps).to be >= 60
  end
end
```

### 3. Upload Duration Test
```ruby
# spec/performance/upload_spec.rb
require 'rails_helper'

RSpec.describe "Image Upload Performance", type: :performance do
  it "uploads 10MB file within acceptable time" do
    collage = create(:collage)
    file = fixture_file_upload('10mb_image.jpg', 'image/jpeg')

    start = Time.now
    post collage_photos_path(collage.rw_guid), params: { photo: { image: file } }
    duration = (Time.now - start) * 1000

    expect(response).to have_http_status(:created)
    expect(duration).to be < 1000  # 1 second server processing
  end
end
```

### 4. Memory Usage Test
```javascript
// spec/performance/memory_spec.js (Capybara + Chrome)
describe("Memory Usage", () => {
  it("does not leak memory after navigating away", async () => {
    const initialHeap = await page.metrics().then(m => m.JSHeapUsedSize);

    // Load page with 20 photos
    await page.goto('/collages/test-guid');
    await page.waitForSelector('.photo');

    const loadedHeap = await page.metrics().then(m => m.JSHeapUsedSize);

    // Navigate away
    await page.goto('/');
    await page.evaluate(() => {
      if (window.gc) window.gc();  // Force GC
    });

    const afterHeap = await page.metrics().then(m => m.JSHeapUsedSize);

    // Heap should return close to initial size (within 20% tolerance)
    expect(afterHeap).to be < initialHeap * 1.2;
  });
});
```

## Performance Comparison Table (To Be Filled)

| Metric | Legacy (Rails 3.2 + Backbone) | Modern (Rails 7.2 + Hotwire) | Change |
|--------|------------------------------|------------------------------|--------|
| Page Load (TTI) | TBD ms | TBD ms | TBD % |
| First Contentful Paint | TBD ms | TBD ms | TBD % |
| Largest Contentful Paint | TBD ms | TBD ms | TBD % |
| Total Blocking Time | TBD ms | TBD ms | TBD % |
| Drag FPS (5 photos) | TBD fps | ≥60 fps | TBD % |
| Drag FPS (20 photos) | TBD fps | ≥60 fps | TBD % |
| Drag FPS (50 photos) | TBD fps | ≥60 fps | TBD % |
| Upload 1MB | TBD ms | TBD ms | TBD % |
| Upload 5MB | TBD ms | TBD ms | TBD % |
| Upload 10MB | TBD ms | TBD ms | TBD % |
| JS Heap (5 photos) | TBD MB | TBD MB | TBD % |
| JS Heap (20 photos) | TBD MB | TBD MB | TBD % |
| JS Heap (50 photos) | TBD MB | TBD MB | TBD % |
| Bundle Size (JS) | TBD KB | TBD KB | TBD % |
| Bundle Size (CSS) | TBD KB | TBD KB | TBD % |

## Known Performance Issues (To Be Fixed)

### Critical
1. **No FPS throttling during resize**: Every mousemove triggers full grid reflow
2. **O(n) grid re-render**: Entire collection re-rendered on every dimension change
3. **No virtualization**: All photos rendered in DOM (not scalable for large collages)

### Medium
4. **Large bundle size**: Backbone + Underscore + jQuery + Plupload (multiple runtimes)
5. **No asset minification in development**: Sprockets not optimized
6. **Memory leaks**: Backbone view bindings not properly cleaned up

### Low
7. **No lazy loading**: All images loaded immediately
8. **No image optimization**: No WebP support, no responsive images
9. **No service worker**: No offline support or caching strategy

## Optimization Opportunities (Phase P3)

### High Impact
1. **Throttle resize with requestAnimationFrame**:
   ```javascript
   let rafId;
   $(document).mousemove((e) => {
     if (rafId) return;
     rafId = requestAnimationFrame(() => {
       // Update dimensions
       rafId = null;
     });
   });
   ```

2. **Incremental grid updates** (instead of full reflow):
   - Only re-render affected photos
   - Use CSS transforms for position changes (no layout recalc)

3. **Virtualization for large collages**:
   - Only render visible photos
   - Render off-screen photos on scroll

### Medium Impact
4. **Modern bundle optimization**:
   - Replace Backbone + jQuery + Underscore with Stimulus (~10KB)
   - Remove Plupload runtimes (keep only HTML5)
   - Use import maps instead of Sprockets

5. **Image optimization**:
   - ActiveStorage variants for responsive images
   - WebP format with JPEG fallback
   - Lazy loading with `loading="lazy"`

### Low Impact
6. **Service worker for offline support**
7. **HTTP/2 server push for assets**
8. **CDN for static assets**

## Testing Tools

### Lighthouse (Chrome DevTools)
```bash
lighthouse http://localhost:3000/collages/test-guid \
  --output html \
  --output-path performance-report.html \
  --throttling.cpuSlowdownMultiplier=4 \
  --throttling.requestLatencyMs=150
```

### Chrome DevTools Performance Panel
1. Open DevTools → Performance tab
2. Click Record
3. Perform action (resize, upload, etc.)
4. Stop recording
5. Analyze timeline

### Memory Profiler
1. Open DevTools → Memory tab
2. Take heap snapshot
3. Perform action
4. Take another snapshot
5. Compare allocations

### Network Performance
1. Open DevTools → Network tab
2. Throttle to Slow 3G or Fast 3G
3. Measure upload time

## Acceptance Criteria for Phase P5

**All performance tests MUST pass**:
- ✅ Page load <100ms (TTI)
- ✅ Drag-and-drop ≥60fps for up to 50 photos
- ✅ 10MB upload completes successfully
- ✅ No memory leaks (heap returns to baseline after navigation)
- ✅ No performance regressions vs baseline

**Performance improvements (nice to have)**:
- Bundle size reduced by ≥50%
- FPS improved for large collages (50+ photos)
- Lighthouse score ≥90

---

**Status**: ✅ Performance baseline documented
**Next Step**: T049 - Implement performance test suite with actual metrics
**Validation**: Run all performance tests in Phase P5 and compare to baseline
