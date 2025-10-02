class Photo
  include Mongoid::Document
  include GlobalID::Identification

  field :caption, type: String

  field :ordinal, type: Integer
  index ordinal: 1

  field :size, type: Integer
  field :height, type: Integer
  field :width, type: Integer
  field :custom_aspect, type: Boolean

  # Image upload using CarrierWave
  mount_uploader :image, ImageUploader
  field :image_height, type: Integer
  field :image_width, type: Integer
  field :image_hash, type: String

  embedded_in :collage

  before_create :set_ordinal
  before_save :set_default_dimensions

  # Image URL using CarrierWave
  def image_url
    image.url if image.present?
  end

  # Image variants using CarrierWave versions
  def image_thumb_url
    image.thumb.url if image.present?
  end

  def image_grid_url
    image.grid.url if image.present?
  end

  def as_json(params = {})
    super(
      {
        only: [:caption, :ordinal, :image_height, :image_width, :image_hash, :custom_aspect],
        methods: [:id, :image_url, :size, :height, :width]
      }.merge(params || {})
    )
  end

  private
  def set_ordinal
    # Set ordinal to the next available value (max + 1)
    self.ordinal ||= (collage.photos.map(&:ordinal).compact.max || -1) + 1
  end

  def set_default_dimensions
    unless self.height && self.width && self.height * self.width == self.size
      factors = (self.size ||= 1).factors

      # set target aspect
      if custom_aspect
        aspect = self.height / self.width.to_f
      else
        aspect = self.image_height / self.image_width.to_f
      end

      high = factors.count - 1
      nearest_index = low = 0

      until high < low
        index = (low + high) / 2
        distance = (factors[index] / (self.size / factors[index]).to_f) - aspect

        if (!defined? nearest_distance) || nearest_distance > distance.abs
          nearest_index = index
          nearest_distance = distance.abs
        end

        if distance < 0
          low = index + 1
        elsif distance > 0
          high = index - 1
        else
          break
        end
      end

      self.height = factors[nearest_index]
      self.width = size / factors[nearest_index]
    end
  end
end
