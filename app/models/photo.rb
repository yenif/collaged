class Photo
  include Mongoid::Document

  field :caption, type: String

  field :ordinal, type: Integer
  index :ordinal

  mount_uploader :image, ImageUploader

  embedded_in :collage

  attr_accessible :caption, :ordinal, :image

  def as_json(params = {})
    super(
      {
        only: [:id,:caption, :ordinal],
        methods: [:image_url]
      }.merge(params || {})
    )
  end

  def image_url
    self.image.url
  end
end
