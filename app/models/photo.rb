class Photo
  include Mongoid::Document

  field :caption, type: String

  field :ordinal, type: Integer
  index :ordinal

  mount_uploader :image, ImageUploader
  field :image_height, type: Integer
  field :image_width, type: Integer
  field :image_hash, type: String

  embedded_in :collage

  attr_accessible :caption, :ordinal, :image

  def as_json(params = {})
    super(
      {
        only: [:id,:caption, :ordinal, :image_height, :image_width, :image_hash],
        methods: [:image_url]
      }.merge(params || {})
    )
  end

  def image_url
    self.image.url
  end
end
