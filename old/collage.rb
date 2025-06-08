class Collage
  include Mongoid::Document

  field :r_guid, type: String
  index({r_guid: 1}, {unique: true})

  field :rw_guid, type: String
  index({rw_guid: 1}, {unique: true})

  before_validation :initialize_guids, on: :create

  field :title, type: String

  embeds_many :photos, order: [[:ordinal, :asc]]

  validates_presence_of :r_guid
  validates_presence_of :rw_guid
  validates_presence_of :title

  attr_accessible :title

  after_initialize :write_access_on_initialize
  attr_accessor :write_access
  def write_access
    !!@write_access
  end

  def rw_guid
    self[:rw_guid] if write_access
  end

  def as_json(params = {})
    super(
      {
        only: [:r_guid, :rw_guid, :title, :write_access]
      }.merge(params || {})
    ).merge(
      { id: self.to_param }
    )
  end

  def self.find_by_guid(guid)
    res = self.any_of({r_guid: guid},{rw_guid: guid}).first
    if res && res.rw_guid == guid
      res.write_access = true
    end
    return res
  end

  def self.find_by_guid!(*args)
    self.find_by_guid(*args) || raise(Mongoid::Errors::DocumentNotFound)
  end

  def to_param
    write_access ? rw_guid : r_guid
  end

  protected
  def write_access_on_initialize(*args)
    self.write_access = true
  end

  def initialize_guids
    begin
      r = self.rw_guid = UUIDTools::UUID.random_create.to_s()
      rw = self.r_guid = UUIDTools::UUID.random_create.to_s()
    end until self.class.any_of(
      {r_guid: r},{rw_guid: r},
      {r_guid: rw},{rw_guid: rw},
    ).count == 0

    return true
  end
end
