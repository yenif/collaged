CarrierWave.configure do |config|
  config.storage = :file
  config.cache_dir = Rails.root.join('tmp', 'uploads')
  # Review old/carrierwave.rake for any relevant settings to migrate manually.
end
