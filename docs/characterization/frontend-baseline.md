# Frontend Baseline - Collaged Application

**Date**: 2025-09-30
**Purpose**: Document legacy JavaScript behavior before Backbone.js → Hotwire migration

## Technology Stack

### Core Libraries

1. **Backbone.js** (version unknown - vendored in lib/)
   - MVC framework for client-side logic
   - Routes, Models, Collections, Views

2. **Underscore.js** (vendored in lib/)
   - Utility library (dependency of Backbone)
   - Template engine with custom settings

3. **jQuery** (via jquery-rails gem)
   - DOM manipulation
   - AJAX requests
   - Event handling
   - UJS (Unobtrusive JavaScript) support

4. **Plupload** (vendored in lib/plupload/)
   - Multi-runtime file upload library
   - Supports: HTML5, Flash, Silverlight, Gears, BrowserPlus, HTML4

## Application Architecture

### Asset Pipeline Structure

**Location**: `/Users/bf/Code/claude/collaged/app/assets/javascripts/`

**Manifest** (`application.js`):
```javascript
//= require jquery
//= require jquery_ujs
//= require lib/underscore.js
//= require lib/backbone.js
//= require lib/plupload/plupload.js
//= require_tree ./lib
//= require_tree ./lib/plupload
//= require_tree ./models
//= require_tree ./views
//= require_tree ./routers
//= require_tree
//= require_self
```

**Load Order**:
1. jQuery + UJS
2. Underscore.js
3. Backbone.js
4. Plupload core + runtimes
5. Models (Collage, Photo)
6. Views (CollageNew, CollageShow, CollagePhotosView, PhotoView)
7. Routers (AppRouter)

### Initialization

**Bootstrap Code** (`application.js`):
```javascript
// Configure Underscore templates to use {{ }} syntax (mustache-style)
// Avoids conflict with ERB <%= %> tags
_.templateSettings = {
    interpolate : /\{\{(.+?)\}\}/g
};

// Initialize on DOM ready
$(function(){
  window.app = new AppRouter
  Backbone.history.start({pushState: true})  // HTML5 pushState routing
});
```

**Key Behaviors**:
- Uses HTML5 pushState for navigation (no hash fragments)
- Initializes single global `window.app` router instance
- Templates use `{{ }}` for interpolation (not ERB-style `<%= %>`)

## Routing

**File**: `app/assets/javascripts/routers/app.js.coffee`

**Routes**:
```coffeescript
routes:
  '/collages/:guid': 'collage_show'
  'collages/:guid':  'collage_show'  # Handles both /collages and collages
  '':                'collage_new'   # Homepage
```

**Route Handlers**:

1. **`collage_new`** (Homepage - Create new collage)
   - Renders `CollageNew` view
   - Bound to `div#content` element

2. **`collage_show`** (Show existing collage)
   - Fetches collage by GUID
   - Renders `CollageShow` view
   - Bound to `div#content` element

**Navigation Pattern**:
- Uses `app.navigate(url, true)` to change routes
- Sets `window.view` global for current view instance

## Models

### Collage Model

**File**: `app/assets/javascripts/models/collage.js.coffee`

**Structure**:
```coffeescript
class Collage extends Backbone.Model
  photos: => PhotoCollection with nested URL
  validate: => title must not be blank

class window.CollageCollection extends Backbone.Collection
  model: Collage
  url: '/collages'

window.Collage = new CollageCollection([],{url: '/collages'})
```

**Key Behaviors**:
- `window.Collage` is a **singleton collection** instance (not a class)
- Photos accessed via `collage.photos()` method (lazy-initialized collection)
- Client-side validation: title required
- RESTful API at `/collages`

### Photo Model

**File**: `app/assets/javascripts/models/photo.js.coffee`

**Grid Dimension Logic** (mirrors Ruby backend):

```coffeescript
class Photo extends Backbone.Model
  size: (s) => get/set size, recalculate dimensions
  height: (h) => get/set height, set custom_aspect, recalculate size
  width: (w) => get/set width, set custom_aspect, recalculate size
  custom_aspect: (b) => boolean flag for custom aspect ratio
  image_height: => original image height
  image_width: => original image width
  set_default_dimensions: => binary search for best aspect fit
```

**Dimension Calculation Algorithm**:
1. If `width × height == size`, skip calculation
2. Get factors of size using `Math.factors()` (JavaScript extension)
3. Determine target aspect ratio:
   - If `custom_aspect == true`: use `height / width`
   - Else: use `image_height / image_width`
4. **Binary search** through factors array to find nearest aspect match:
   - Calculate distance: `(factor / (size / factor)) - aspect`
   - Track nearest_distance and nearest_index
5. Set height = `factors[nearest_index]`, width = `size / factors[nearest_index]`

**Key Behaviors**:
- Dimensions calculated **client-side** (duplicates Ruby logic)
- Changing width/height sets `custom_aspect = true`
- Changing size recalculates dimensions
- Uses prime factorization for grid fitting

**Dependencies**:
- Requires `Math.factors()` extension (must exist in lib/)

## Views

### CollageNew View (Homepage)

**File**: `app/assets/javascripts/views/collage_new.js.coffee.erb`

**Behavior**:
- Renders form for creating new collage
- Button `.button.create` triggers AJAX POST
- On success: navigates to `collage.url()` (show page)
- Uses Underscore template: `<%= Templater.render_template :collage_new %>`

**API Call**:
```coffeescript
Collage.create({
  title: $('input#title').val()
},{
  success: (collection, response) ->
    app.navigate(collage.url(),true)
})
```

### CollageShow View (Collage Editor)

**File**: `app/assets/javascripts/views/collage_show.js.coffee.erb`

**Responsibilities**:
1. Display collage metadata
2. Initialize Plupload for photo uploads
3. Render CollagePhotosView (grid layout)
4. Handle upload events (progress, errors, completion)

**Plupload Configuration**:
```coffeescript
@uploader = new plupload.Uploader({
  runtimes : 'gears,html5,flash,silverlight,browserplus',
  browse_button : 'pickfiles',      # File picker button ID
  drop_element : 'content',         # Drag-and-drop target
  container : 'toolbox',            # Container element
  max_file_size : '10mb',           # Size limit
  url : this.model.photos().url,   # Upload endpoint
  file_data_name: 'photo[image]',  # Form field name
  multipart : true,
  multipart_params : {},
  headers : {
    Accept : 'application/json',
    'X-CSRF-Token' : $('meta[name="csrf-token"]').attr('content')
  },
  flash_swf_url : '/plupload.flash.swf',
  silverlight_xap_url : '/plupload.silverlight.xap',
  filters : [
    {title : "Image files", extensions : "jpg,gif,png"},
  ]
})
```

**Plupload Runtime Selection**:
- **Priority Order**: gears → html5 → flash → silverlight → browserplus
- Runtime determined at initialization based on browser support
- Displays selected runtime in UI: `$('#filelist').html("Current runtime: " + params.runtime)`

**Upload Flow**:

1. **Init Event**: Display selected runtime to user
2. **FilesAdded Event**:
   - Append file names with sizes to `#filelist`
   - Call `up.refresh()` to reposition Flash/Silverlight
   - Auto-start upload with `up.start()`
3. **UploadProgress Event**:
   - Update progress: `$('#' + file.id + " b").html(file.percent + "%")`
4. **Error Event**:
   - Display error message with code, message, filename
5. **FileUploaded Event**:
   - Parse JSON response
   - Add photo to collection: `this.model.photos().add($.parseJSON(response.response))`
   - Set progress to 100%

**Key Behaviors**:
- Binds to model `change` event → re-render
- Fetches photos on initialization if collection empty
- Creates nested `CollagePhotosView` for grid layout
- Re-initializes Plupload on each render (necessary for Flash/Silverlight positioning)

### CollagePhotosView (Grid Layout Engine)

**File**: `app/assets/javascripts/views/collage_photos_view.js.coffee.erb`

**Grid Constants**:
```coffeescript
padding: 10           # px padding around container
grid_width = 8        # cells (dynamic, recalculated on render)
grid_x_inc = 100      # px per cell width
grid_y_inc = 100      # px per cell height
```

**State Variables**:
```coffeescript
y_offset = 0    # Current row offset
x = 0           # Current column position
grid = []       # 2D array tracking occupied cells
```

**Grid Layout Algorithm** (`add_photo` method):

```
1. Check if current x position exceeds grid_width
   - If yes: reset x=0, shift grid array, increment y_offset
2. Ensure grid[0] row exists (create if needed)
3. Check for overlap:
   - For each cell from x to x+photo.width():
     - If x+i >= grid_width OR grid[0][x+i] is occupied: overlap = true
4. If no overlap:
   - Append PhotoView to DOM with calculated position:
     - x_pos = x × grid_x_inc + padding
     - y_pos = y_offset × grid_y_inc + padding
     - width = photo.width() × grid_x_inc
     - height = photo.height() × grid_y_inc
   - Mark grid cells as occupied for photo.height() rows
   - Increment x by photo.width()
   - Return photo_view
5. If overlap:
   - Increment x by 1
   - Repeat from step 1
```

**Key Behaviors**:
- **Left-to-right, top-to-bottom packing** (like text flow)
- **Dynamic grid width**: Recalculates based on container width
- **Collision detection**: Tracks occupied cells in 2D grid array
- **No backtracking**: Once a row is past (shifted from grid[0]), photos can't be placed there
- **Automatic reflow**: Calling `render()` rebuilds entire grid from scratch

**Resize Handling**:

```coffeescript
handle_resize: (view, callback) =>
  origin = $(view.el).offset()
  $(document).mousemove (e) =>
    x = Math.round((e.pageX - origin.left)/grid_x_inc)
    y = Math.round((e.pageY - origin.top)/grid_y_inc)

    # Enforce minimum 1x1
    x = 1 if x < 1
    y = 1 if y < 1

    if x != view.model.width() || y != view.model.height()
      view.model.width(x)
      view.model.height(y)
      @render()  # Trigger full grid reflow

  $(document).mouseup (f) =>
    $(document).unbind('mousemove')
    callback(f)  # Calls end_spatial_edit → model.save()
```

**Resize Characteristics**:
- **Snaps to grid cells** (100px increments)
- **No upper-left resize support** (comment in code: "currently don't support resize to the upper left")
- **Minimum size**: 1×1 cells
- **Triggers reflow** on every dimension change
- **Last-write-wins**: No locking, concurrent edits overwrite

### PhotoView (Individual Photo)

**File**: `app/assets/javascripts/views/photo_view.js.coffee.erb`

**Edge Detection for Resize** (`start_spatial_edit` method):

```coffeescript
x = e.offsetX  # Relative to photo element
y = e.offsetY

if x < 10
  @resize_left = true
else if x > @width - 10
  @resize_right = true

if y < 10
  @resize_top = true
else if y > @height - 10
  @resize_bottom = true
```

**Resize vs Move Detection**:
- **Resize**: If within 10px of any edge (left, right, top, bottom)
- **Move**: If not near any edge (currently triggers but does nothing)

**Image Aspect Fitting** (`dim` method):

```coffeescript
if h/w > image_aspect
  # Photo is taller than image → fit height, center horizontally
  image_height = h
  image_width = 'auto'
  image_left = calculated_offset  # Center crop
else
  # Photo is wider than image → fit width, center vertically
  image_height = 'auto'
  image_width = w
  image_top = calculated_offset  # Center crop
```

**Key Behaviors**:
- **Cover fit**: Image fills entire cell, cropped if necessary
- **Center crop**: Overflow is centered (not edge-aligned)
- **2px border**: Dimensions reduced by 2px for border/padding
- **Absolute positioning**: Uses CSS `left`, `top`, `width`, `height`

## Critical Frontend Behaviors to Preserve

### 1. Plupload Multi-Runtime Support

**Current Implementation**:
- Attempts runtimes in order: Gears → HTML5 → Flash → Silverlight → BrowserPlus
- Falls back to HTML4 as last resort
- Displays selected runtime to user for transparency
- Handles Flash/Silverlight positioning with `up.refresh()`

**Browser Compatibility** (circa 2013):
- **HTML5**: Modern browsers (Chrome, Firefox, Safari, IE10+)
- **Flash**: Older browsers with Flash plugin
- **Silverlight**: IE with Silverlight plugin
- **Gears**: Google Gears (obsolete)
- **BrowserPlus**: Yahoo BrowserPlus (obsolete)
- **HTML4**: Fallback for ancient browsers

**Modern Migration Path** (Hotwire):
- Replace Plupload with **ActiveStorage Direct Upload** (HTML5 File API)
- Drop Flash/Silverlight/Gears/BrowserPlus runtimes (no longer necessary)
- Maintain multi-file selection and drag-and-drop

### 2. Multi-File Upload with Progress

**Current Flow**:
1. User selects/drops multiple files
2. Each file added to queue immediately
3. Auto-start upload for all files
4. Show per-file progress with percentage
5. On completion: Add photo to collection → grid re-renders

**Key Features**:
- **Multi-file selection**: Via file picker or drag-and-drop
- **Auto-start**: No manual "Upload" button click needed (configured behavior)
- **Per-file progress**: Individual percentage for each file
- **Streaming**: Files upload in parallel (Plupload handles queue)

### 3. Drag-and-Drop Resize

**Interaction Flow**:
1. User mousedown within 10px of any photo edge
2. Cursor tracks mouse position (converted to grid coordinates)
3. Grid dimensions update in real-time (triggers reflow)
4. On mouseup: Save photo model to backend

**Characteristics**:
- **10px edge detection zone** (all four sides)
- **Grid-snapped**: Rounds to nearest cell (100px increments)
- **Real-time feedback**: Grid re-renders on every mousemove
- **No resize handles**: Detection based on cursor position only
- **No upper-left resize**: Only bottom/right edges functional (per code comment)

**Performance Considerations**:
- Re-renders entire grid on every mousemove during resize
- No throttling/debouncing of render calls
- Potential performance issues with many photos (should target 60fps)

### 4. Grid Layout and Reflow

**Packing Algorithm**:
- **Greedy left-to-right flow**: Like text wrapping
- **No optimal packing**: First-fit approach (not bin-packing algorithm)
- **Dynamic grid width**: Adjusts to container width
- **Full reflow on resize**: Entire grid rebuilds from scratch
- **No photo repositioning**: Photos stay in ordinal order

**Collision Handling**:
- If photo doesn't fit at current x: try x+1
- If photo doesn't fit in current row: move to next row
- No backfilling of gaps in previous rows

### 5. Client-Side Dimension Calculation

**Duplicated Logic**:
- JavaScript `Photo.set_default_dimensions()` mirrors Ruby `Photo#set_default_dimensions`
- Both use same binary search algorithm
- Both depend on `Integer#factors` / `Math.factors`

**Why Duplicated?**:
- Enables **instant client-side feedback** during resize
- Avoids round-trip to server for dimension calculation
- Grid can re-render immediately without waiting for save

**Risk**:
- Logic drift between client and server
- Must maintain parity during modernization

### 6. Template Rendering

**Current Approach**:
- ERB templates rendered server-side
- Accessed via `Templater.render_template` Ruby helper
- Embedded as strings in `.js.coffee.erb` files
- Underscore.js `_.template()` compiles at runtime

**Template Interpolation**:
- Uses `{{ variable }}` syntax (not `<%= %>`)
- Configured in `application.js`: `_.templateSettings = { interpolate : /\{\{(.+?)\}\}/g }`

**Templates Referenced**:
- `:collage_new` - New collage form
- `:collage_show` - Collage editor layout
- `:photo_show` - Individual photo rendering

### 7. State Management

**Global Variables**:
- `window.app` - AppRouter instance
- `window.view` - Current active view instance
- `window.Collage` - Singleton collection (not a class!)
- `window.collage` - Current collage instance (set in CollageNew)

**View Binding**:
- Models bind to `change` events → auto-render
- Collections bind to `add`/`reset` events → update views
- Circular references: `model.view = this`, `collection.view = this`

**Data Flow**:
1. User action triggers event
2. Event handler updates model/collection
3. Model fires `change` event
4. View bound to event re-renders
5. No explicit state management (relies on Backbone events)

## Dependencies to Remove/Replace

### Libraries to Remove
- ✅ Backbone.js → Hotwire Turbo Frames
- ✅ Underscore.js → Native ES6+ (map, filter, etc.)
- ✅ jQuery → Native DOM APIs or Stimulus
- ✅ Plupload → ActiveStorage Direct Upload

### Legacy Runtimes (No Longer Needed)
- ❌ Flash (`plupload.flash.js`, `plupload.flash.swf`)
- ❌ Silverlight (`plupload.silverlight.js`, `plupload.silverlight.xap`)
- ❌ Gears (`plupload.gears.js`)
- ❌ BrowserPlus (`plupload.browserplus.js`)
- ❌ HTML4 (`plupload.html4.js`)
- ✅ HTML5 (`plupload.html5.js`) → Replace with File API

### Custom Extensions to Port
- ✅ `Math.factors()` - JavaScript integer factorization (port to Stimulus helper)
- ✅ Template system - Replace with Rails 7 Turbo Frames

## Performance Characteristics (Baseline)

### Grid Rendering
- **Full re-render on resize**: O(n) where n = number of photos
- **No virtualization**: All photos rendered in DOM
- **No throttling**: mousemove triggers immediate render
- **Target**: 60fps (16.67ms frame budget)

### Upload Handling
- **Concurrent uploads**: Plupload manages queue
- **Max file size**: 10MB (enforced client-side)
- **Progress updates**: Real-time per-file percentage
- **Duplicate detection**: Not implemented client-side (server handles via SHA1)

### Browser Support (2013 Era)
- IE 8+, Firefox 3.6+, Chrome, Safari 5+, Opera 11+
- Flash Player 9+ for Flash runtime
- Silverlight 4+ for Silverlight runtime

## Migration Risks and Considerations

### High-Risk Areas
1. **Grid layout algorithm**: Complex packing logic, must preserve exact behavior
2. **Dimension calculation**: Duplicated client/server logic, must stay in sync
3. **Resize interaction**: 10px edge detection, grid snapping, real-time feedback
4. **Upload flow**: Multi-file, progress tracking, duplicate detection

### Medium-Risk Areas
1. **Routing**: Backbone pushState → Turbo navigation
2. **Template rendering**: Underscore → Rails partials/Turbo Frames
3. **State management**: Backbone events → Stimulus actions

### Low-Risk Areas
1. **Plupload runtimes**: HTML5 File API is standard now
2. **jQuery → Native**: Most jQuery can be replaced with modern DOM APIs
3. **Underscore utility functions**: ES6+ has equivalents

## Testing Requirements for Migration

### Critical Paths to Test
1. **Collage creation**: Title validation, navigation to show page
2. **Photo upload**: Multi-file, progress, duplicate detection, 10MB limit
3. **Grid layout**: Left-to-right flow, collision detection, dynamic width
4. **Photo resize**: Edge detection (10px), grid snapping, reflow, save
5. **Aspect ratio**: Cover fit with center crop
6. **Performance**: 60fps during resize/reflow

### Browser Testing
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

### Accessibility Testing
- Keyboard navigation for file picker
- Screen reader compatibility
- Focus management during Turbo navigation

---

**Status**: ✅ Frontend behavior fully characterized
**Next Phase**: P3 (Frontend Modernization) can proceed with confidence
