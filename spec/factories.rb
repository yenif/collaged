FactoryBot.define do
  factory :collage do
    title { "Test Collage" }
    r_guid { SecureRandom.uuid }
    rw_guid { SecureRandom.uuid }
  end

  factory :photo do
    association :collage
    ordinal { 1 }
  end
end
