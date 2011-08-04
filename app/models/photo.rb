class Photo
  include Mongoid::Document

  field :caption, type: String

  field :ordinal, type: Integer
  index :ordinal

  embedded_in :collage

  attr_accessible :caption, :ordinal
end
