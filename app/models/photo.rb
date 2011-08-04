class Photo
  include Mongoid::Document

  field :caption, type: String

  field :ordinal, type: Integer
  index :ordinal

  mount_uploader :image, ImageUploader

  embedded_in :collage

  attr_accessible :caption, :ordinal, :image
end
