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

  # ActiveStorage attachment (modern)
  has_one_attached :image

  # CarrierWave (legacy - temporary during migration)
  mount_uploader :legacy_image, ImageUploader
  field :image_height, type: Integer
  field :image_width, type: Integer
  field :image_hash, type: String

  embedded_in :collage

  before_save :set_default_dimensions

  # Dual-read pattern: Try ActiveStorage first, fallback to CarrierWave
  def image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
    elsif legacy_image.present?
      legacy_image.url
    end
  end

  # Image variants for ActiveStorage
  def image_thumb_url
    return nil unless image.attached?
    Rails.application.routes.url_helpers.rails_representation_url(
      image.variant(resize_to_limit: [150, 150]),
      only_path: true
    )
  end

  def image_grid_url
    return nil unless image.attached?
    Rails.application.routes.url_helpers.rails_representation_url(
      image.variant(resize_to_limit: [800, 800]),
      only_path: true
    )
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
