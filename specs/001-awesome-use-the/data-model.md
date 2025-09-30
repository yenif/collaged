# Data Model: Collaged Modernization

**Feature**: Full Dependency Modernization
**Date**: 2025-09-30
**Status**: Phase 1 Design

## Overview

The Collaged application uses MongoDB with Mongoid ODM. The data model consists of two primary entities with an embedded relationship. This document specifies the schema for both legacy (Mongoid 3.x) and modern (Mongoid 9.x) implementations to ensure data preservation during migration.

## Entities

### Collage

**Purpose**: Container for a collection of photos with unique access control via GUIDs.

**Mongoid Model** (target Rails 7 + Mongoid 9.x):
```ruby
class Collage
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :title, type: String
  field :r_guid, type: String      # Read-only GUID
  field :rw_guid, type: String     # Read-write GUID

  # Indexes
  index({ r_guid: 1 }, { unique: true })
  index({ rw_guid: 1 }, { unique: true })

  # Associations
  embeds_many :photos, order: :ordinal.asc

  # Validations
  validates :title, presence: true
  validates :r_guid, presence: true, uniqueness: true
  validates :rw_guid, presence: true, uniqueness: true

  # Callbacks
  before_validation :initialize_guids, on: :create
  after_initialize :write_access_on_initialize

  # Virtual Attributes
  attr_accessor :write_access

  # Methods
  def write_access
    !!@write_access
  end

  def rw_guid
    self[:rw_guid] if write_access
  end

  def to_param
    write_access ? rw_guid : r_guid
  end

  # Class Methods
  def self.find_by_guid(guid)
    collage = any_of({ r_guid: guid }, { rw_guid: guid }).first
    if collage && collage[:rw_guid] == guid
      collage.write_access = true
    end
    collage
  end

  def self.find_by_guid!(guid)
    find_by_guid(guid) || raise(Mongoid::Errors::DocumentNotFound.new(self, guid))
  end

  private

  def write_access_on_initialize
    self.write_access = true if new_record?
  end

  def initialize_guids
    loop do
      self.r_guid = SecureRandom.uuid
      self.rw_guid = SecureRandom.uuid

      break if self.class.where(
        '$or' => [
          { r_guid: { '$in' => [r_guid, rw_guid] } },
          { rw_guid: { '$in' => [r_guid, rw_guid] } }
        ]
      ).count.zero?
    end
    true
  end
end
```

**Schema**:
| Field | Type | Required | Unique | Default | Notes |
|-------|------|----------|--------|---------|-------|
| `_id` | ObjectId | Yes | Yes | Auto | MongoDB primary key |
| `title` | String | Yes | No | - | User-provided collage title |
| `r_guid` | String (UUID) | Yes | Yes | Generated | Read-only access identifier |
| `rw_guid` | String (UUID) | Yes | Yes | Generated | Read-write access identifier |
| `created_at` | DateTime | Yes | No | Auto | Timestamp (Mongoid) |
| `updated_at` | DateTime | Yes | No | Auto | Timestamp (Mongoid) |

**Relationships**:
- `embeds_many :photos` - One-to-many embedded relationship with Photo documents

**Business Rules**:
1. Both `r_guid` and `rw_guid` must be globally unique across all collages
2. `rw_guid` only exposed when `write_access` flag is true
3. Title must be non-empty string
4. GUIDs generated using `SecureRandom.uuid` (replaces legacy UUIDTools)
5. Uniqueness check prevents GUID collisions during generation

**Access Control**:
- URL contains either `r_guid` (read-only) or `rw_guid` (read-write)
- `find_by_guid` method determines access level based on which GUID matches
- `write_access` virtual attribute controls GUID exposure and edit permissions

**Migration Notes**:
- Legacy used UUIDTools gem; modern uses Ruby stdlib `SecureRandom.uuid`
- Mongoid 3.x → 9.x: `order` syntax changed from array to method chaining
- Embedded documents stored directly in parent document (no joins)

---

### Photo

**Purpose**: Uploaded image with positioning metadata for grid layout.

**Mongoid Model** (target Rails 7 + Mongoid 9.x):
```ruby
class Photo
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :caption, type: String
  field :ordinal, type: Integer
  field :size, type: Integer              # Grid cell count (width * height)
  field :height, type: Integer            # Grid cells vertically
  field :width, type: Integer             # Grid cells horizontally
  field :custom_aspect, type: Boolean, default: false
  field :image_height, type: Integer      # Original image height (pixels)
  field :image_width, type: Integer       # Original image width (pixels)
  field :image_hash, type: String         # SHA1 hash for duplicate detection

  # Indexes
  index ordinal: 1
  index image_hash: 1

  # Associations
  embedded_in :collage

  # ActiveStorage attachment (modern)
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :grid, resize_to_fill: [800, 600]
    attachable.variant :full, resize_to_limit: [1920, 1080]
  end

  # Validations
  validates :ordinal, presence: true
  validates :size, presence: true, numericality: { greater_than: 0 }
  validates :image, presence: true, on: :create

  # Callbacks
  before_save :set_default_dimensions

  # Accessible Attributes (legacy Rails 3 attr_accessible → strong params in Rails 7)
  # attr_accessible :caption, :ordinal, :image, :size, :height, :width, :custom_aspect

  # Methods
  def image_url
    image.attached? ? Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true) : nil
  end

  def as_json(options = {})
    super({
      only: [:caption, :ordinal, :image_height, :image_width, :image_hash, :custom_aspect],
      methods: [:id, :image_url, :size, :height, :width]
    }.merge(options || {}))
  end

  private

  def set_default_dimensions
    return if height && width && (height * width == size)

    factors = (size || 1).factors

    # Calculate target aspect ratio
    aspect = if custom_aspect && height && width && height.positive? && width.positive?
               height / width.to_f
             elsif image_height && image_width && image_height.positive? && image_width.positive?
               image_height / image_width.to_f
             else
               1.0
             end

    # Binary search for best factor match
    high = factors.count - 1
    nearest_index = low = 0

    until high < low
      index = (low + high) / 2
      distance = (factors[index] / (size / factors[index]).to_f) - aspect

      if !defined?(nearest_distance) || nearest_distance > distance.abs
        nearest_index = index
        nearest_distance = distance.abs
      end

      if distance.negative?
        low = index + 1
      elsif distance.positive?
        high = index - 1
      else
        break
      end
    end

    self.height = factors[nearest_index]
    self.width = size / factors[nearest_index]
  end
end

# Integer extension for factorization (preserved from legacy)
class Integer
  def factors
    1.upto(Math.sqrt(self)).select { |i| (self % i).zero? }.inject([]) do |f, i|
      f << i
      f << self / i unless i == self / i
      f
    end.sort
  end
end
```

**Schema**:
| Field | Type | Required | Unique | Default | Notes |
|-------|------|----------|--------|---------|-------|
| `_id` | ObjectId | Yes | Yes | Auto | MongoDB primary key (embedded doc) |
| `caption` | String | No | No | nil | Optional user caption |
| `ordinal` | Integer | Yes | No | - | Sort order in collage |
| `size` | Integer | Yes | No | 1 | Grid cell count (width × height) |
| `height` | Integer | Auto | No | Calculated | Grid cells vertically |
| `width` | Integer | Auto | No | Calculated | Grid cells horizontally |
| `custom_aspect` | Boolean | No | No | false | True if user manually resized |
| `image_height` | Integer | Auto | No | - | Original image height (px) |
| `image_width` | Integer | Auto | No | - | Original image width (px) |
| `image_hash` | String (SHA1) | Auto | No | - | For duplicate detection |
| `created_at` | DateTime | Yes | No | Auto | Timestamp |
| `updated_at` | DateTime | Yes | No | Auto | Timestamp |

**Relationships**:
- `embedded_in :collage` - Belongs to parent Collage document
- `has_one_attached :image` - ActiveStorage attachment (Rails 7)

**Business Rules**:
1. `size = width × height` (must satisfy this constraint)
2. Minimum size: 1 grid cell (1×1)
3. Dimensions auto-calculated to preserve aspect ratio using prime factorization
4. Custom aspect ratio overrides original image aspect when `custom_aspect=true`
5. Photos ordered by `ordinal` field (ascending)
6. Duplicate detection via SHA1 hash of image data
7. Image variants generated automatically: thumb (200px), grid (800px), full (1920px)

**Grid Layout Algorithm**:
- Uses integer factorization to find optimal width/height split
- Binary search finds closest factor pair matching target aspect ratio
- Target aspect: original image ratio OR custom ratio if manually resized
- Example: size=12 → factors=[1,2,3,4,6,12] → best match for 16:9 ≈ 3×4

**Migration Notes**:
- Legacy: CarrierWave + RMagick → Modern: ActiveStorage + libvips
- `image_url` method changes: CarrierWave path → ActiveStorage blob path
- Image variants: On-demand generation vs pre-generated thumbnails
- Hash calculation: Preserve SHA1 for duplicate detection during migration

---

## Relationships Diagram

```
┌─────────────────────────────────────┐
│ Collage                             │
│ ─────────────────────────────────── │
│ _id: ObjectId (PK)                  │
│ title: String                       │
│ r_guid: String (unique index)       │
│ rw_guid: String (unique index)      │
│ created_at: DateTime                │
│ updated_at: DateTime                │
│                                     │
│ (virtual)                           │
│ write_access: Boolean               │
└─────────────────────────────────────┘
          │
          │ embeds_many
          ├──────────────┐
          │              │
          ▼              ▼
┌─────────────────────────────────────┐
│ Photo                               │
│ ─────────────────────────────────── │
│ _id: ObjectId                       │
│ caption: String?                    │
│ ordinal: Integer (index)            │
│ size: Integer                       │
│ height: Integer (calculated)        │
│ width: Integer (calculated)         │
│ custom_aspect: Boolean              │
│ image_height: Integer               │
│ image_width: Integer                │
│ image_hash: String (index)          │
│ created_at: DateTime                │
│ updated_at: DateTime                │
│                                     │
│ (ActiveStorage)                     │
│ has_one_attached :image             │
│   - variants: thumb, grid, full     │
└─────────────────────────────────────┘
```

**Storage**:
- Collage documents stored in `collages` collection
- Photos embedded directly within parent Collage documents (no separate collection)
- Image blobs stored via ActiveStorage (local filesystem or S3)

**Indexes**:
1. `collages.r_guid` (unique)
2. `collages.rw_guid` (unique)
3. `collages.photos.ordinal` (embedded field index)
4. `collages.photos.image_hash` (embedded field index)

---

## Data Migration Plan

### Phase 1: Schema Compatibility Check
1. Export production MongoDB schema: `mongodump --db collaged_production`
2. Verify field types match specification
3. Check for orphaned data or inconsistencies

### Phase 2: Mongoid Upgrade (3.x → 9.x)
1. Update Gemfile: `gem 'mongoid', '~> 9.0'`
2. Run `rails g mongoid:config` → compare with existing mongoid.yml
3. Test queries in parallel: old vs new Mongoid syntax
4. Update model syntax:
   - `order: [[:ordinal, :asc]]` → `order: :ordinal.asc`
   - Field type validation changes
5. Run test suite: ensure no data access regressions

### Phase 3: Image Migration (CarrierWave → ActiveStorage)
**Rake Task**: `rails collaged:migrate_images`

```ruby
namespace :collaged do
  desc "Migrate CarrierWave images to ActiveStorage"
  task migrate_images: :environment do
    Collage.all.each do |collage|
      collage.photos.each do |photo|
        next if photo.image.attached? # Skip if already migrated

        # Read original CarrierWave file
        old_path = photo.image.path
        next unless File.exist?(old_path)

        # Calculate hash for verification
        blob_data = File.read(old_path)
        hash = Digest::SHA1.hexdigest(blob_data)

        if photo.image_hash != hash
          Rails.logger.warn("Hash mismatch for Photo #{photo.id}")
        end

        # Attach to ActiveStorage
        photo.image.attach(
          io: File.open(old_path),
          filename: File.basename(old_path),
          content_type: Marcel::MimeType.for(Pathname.new(old_path))
        )

        # Verify dimensions
        if photo.image.attached?
          metadata = photo.image.metadata
          puts "Migrated: #{photo.id} (#{metadata['width']}x#{metadata['height']})"
        end
      end
    end
  end
end
```

**Dual-Read Strategy**:
```ruby
# In Photo model during transition
def image_url
  if image.attached?
    Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
  else
    # Fallback to CarrierWave (legacy)
    super
  end
end
```

### Phase 4: GUID Migration (UUIDTools → SecureRandom)
- Existing GUIDs remain unchanged (already valid UUIDs)
- New collages use `SecureRandom.uuid` instead of `UUIDTools::UUID.random_create.to_s`
- No data migration needed, just code change

---

## Validation Queries

**Check collage uniqueness**:
```javascript
// MongoDB shell
db.collages.aggregate([
  { $group: { _id: "$r_guid", count: { $sum: 1 } } },
  { $match: { count: { $gt: 1 } } }
])
// Should return empty (no duplicates)
```

**Check photo grid constraints**:
```javascript
db.collages.aggregate([
  { $unwind: "$photos" },
  { $project: {
      photo_id: "$photos._id",
      valid: { $eq: [
        { $multiply: ["$photos.width", "$photos.height"] },
        "$photos.size"
      ]}
  }},
  { $match: { valid: false } }
])
// Should return empty (all photos satisfy width × height = size)
```

**Count images needing migration**:
```ruby
Photo.where(:image.exists => true).count # CarrierWave count
ActiveStorage::Attachment.where(record_type: 'Photo').count # ActiveStorage count
# After migration, both should equal total photo count
```

---

## Performance Considerations

**Embedded Documents**:
- Pro: Single query loads collage + all photos (no joins)
- Con: Cannot query photos independently
- Decision: Acceptable because photos always accessed via parent collage

**Image Variants**:
- Thumb variant (200px): Instant page load, grid preview
- Grid variant (800px): Drag-and-drop interaction size
- Full variant (1920px): Lightbox/download
- Generation: On-demand + caching (ActiveStorage)

**Index Strategy**:
- `r_guid` + `rw_guid`: Fast collage lookup by URL (O(1) with unique index)
- `ordinal`: Fast sorting for photo display (embedded index)
- `image_hash`: Fast duplicate detection on upload

**Expected Data Volume**:
- Collages: ~1K-10K documents
- Photos per collage: 5-50 (median ~15)
- Image sizes: 1-10MB original, 50-500KB variants
- MongoDB document size: <16MB limit (safe with embedded photos)

---

## Status

✅ Phase 1 Data Model Design Complete
- Schema documented for both legacy and modern implementations
- Migration strategy defined with rollback plan
- Validation queries provided
- Ready for contract generation (Phase 1 next step)
