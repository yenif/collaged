namespace :collaged do
  desc "Migrate CarrierWave images to ActiveStorage"
  task migrate_images: :environment do
    require 'open-uri'
    require 'digest/sha1'

    migrated_count = 0
    skipped_count = 0
    error_count = 0

    puts "Starting image migration from CarrierWave to ActiveStorage..."

    Collage.all.each do |collage|
      collage.photos.each do |photo|
        # Skip if already migrated
        if photo.image.attached?
          puts "  Skipping photo #{photo.id} - already has ActiveStorage attachment"
          skipped_count += 1
          next
        end

        # Skip if no CarrierWave image
        unless photo.legacy_image.present?
          puts "  Skipping photo #{photo.id} - no legacy image found"
          skipped_count += 1
          next
        end

        begin
          # Get the file path from CarrierWave
          file_path = photo.legacy_image.path

          unless File.exist?(file_path)
            puts "  ERROR: File not found: #{file_path}"
            error_count += 1
            next
          end

          # Read the file
          file_data = File.read(file_path)

          # Verify hash if available
          if photo.image_hash.present?
            current_hash = Digest::SHA1.hexdigest(file_data)
            if current_hash != photo.image_hash
              puts "  WARNING: Hash mismatch for photo #{photo.id} (expected: #{photo.image_hash}, got: #{current_hash})"
            end
          end

          # Get original filename
          filename = File.basename(file_path)

          # Attach to ActiveStorage
          photo.image.attach(
            io: StringIO.new(file_data),
            filename: filename,
            content_type: Marcel::MimeType.for(Pathname.new(file_path))
          )

          # Update metadata if needed
          if photo.image.attached? && photo.image.blob.present?
            # Use ImageProcessing to get dimensions
            require 'image_processing/vips'

            analyzer = ActiveStorage::Analyzer::ImageAnalyzer.new(photo.image.blob)
            metadata = analyzer.metadata

            if metadata[:width] && metadata[:height]
              photo.image_width = metadata[:width]
              photo.image_height = metadata[:height]
            end

            # Store hash for the blob
            photo.image_hash = Digest::SHA1.hexdigest(file_data) unless photo.image_hash.present?

            photo.save!

            puts "  Migrated photo #{photo.id} (#{filename})"
            migrated_count += 1
          else
            puts "  ERROR: Failed to attach photo #{photo.id}"
            error_count += 1
          end
        rescue => e
          puts "  ERROR migrating photo #{photo.id}: #{e.message}"
          puts "    #{e.backtrace.first}"
          error_count += 1
        end
      end
    end

    puts "\nMigration complete!"
    puts "  Migrated: #{migrated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Errors: #{error_count}"
  end
end
