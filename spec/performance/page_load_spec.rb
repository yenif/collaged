require 'spec_helper'

RSpec.describe 'Page Load Performance', type: :performance do
  let(:baseline_path) { Rails.root.join('docs/characterization/performance-baseline.md') }

  describe 'Homepage' do
    it 'loads within acceptable time' do
      start_time = Time.now
      get '/'
      load_time = (Time.now - start_time) * 1000 # Convert to milliseconds

      # Target: Structure loads <100ms (Time to Interactive measured via Lighthouse separately)
      expect(response.status).to eq(200)
      expect(load_time).to be < 100

      puts "Homepage load time: #{load_time.round(2)}ms"
    end
  end

  describe 'Collage View' do
    let(:collage) { create(:collage) }

    it 'loads collage view within acceptable time' do
      start_time = Time.now
      get "/collages/#{collage.id}"
      load_time = (Time.now - start_time) * 1000

      expect(response.status).to eq(200)
      expect(load_time).to be < 100

      puts "Collage view load time: #{load_time.round(2)}ms"
    end
  end
end
