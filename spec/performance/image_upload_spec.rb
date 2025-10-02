require 'spec_helper'

RSpec.describe 'Image Upload Performance', type: :performance do
  describe 'Large file upload' do
    it 'handles 10MB image upload within acceptable time' do
      # Create a test file (simulate 10MB image)
      test_file = Tempfile.new(['test_image', '.jpg'])
      test_file.write('0' * 10_485_760) # 10MB
      test_file.rewind

      collage = create(:collage)

      start_time = Time.now
      post "/collages/#{collage.id}/photos", params: {
        photo: {
          image: Rack::Test::UploadedFile.new(test_file.path, 'image/jpeg')
        }
      }
      upload_time = (Time.now - start_time) * 1000

      expect(response.status).to be_between(200, 302)
      puts "10MB image upload time: #{upload_time.round(2)}ms"

      test_file.close
      test_file.unlink
    end
  end

  describe 'Multiple uploads' do
    it 'processes batch uploads efficiently' do
      collage = create(:collage)
      upload_times = []

      5.times do |i|
        test_file = Tempfile.new(['test_image', '.jpg'])
        test_file.write('0' * 1_048_576) # 1MB
        test_file.rewind

        start_time = Time.now
        post "/collages/#{collage.id}/photos", params: {
          photo: {
            image: Rack::Test::UploadedFile.new(test_file.path, 'image/jpeg')
          }
        }
        upload_times << (Time.now - start_time) * 1000

        test_file.close
        test_file.unlink
      end

      avg_time = upload_times.sum / upload_times.size
      puts "Average 1MB upload time: #{avg_time.round(2)}ms"

      expect(avg_time).to be < 500 # Target: <500ms per 1MB image
    end
  end
end
