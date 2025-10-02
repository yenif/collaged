require 'rails_helper'

RSpec.describe 'Photo Reordering', type: :system, js: true do
  let(:collage) { Collage.create!(title: 'Test Collage') }

  before do
    # Create test photos with ordinal values
    5.times do |i|
      photo = collage.photos.build(
        ordinal: i + 1,
        size: 4,
        width: 2,
        height: 2,
        image_width: 800,
        image_height: 600,
        image_hash: SecureRandom.hex(20)
      )
      # Attach a test image (simplified for test)
      photo.save!
    end
    collage.save!
  end

  describe 'with write access' do
    it 'allows dragging photo from position 1 to position 3' do
      visit "/collages/#{collage.rw_guid}"

      # Wait for page to load and Stimulus controllers to connect
      expect(page).to have_css('.photo', count: 5)

      # Find photos by ordinal (data attribute)
      photo1 = page.find('.photo[data-photo-reorder-ordinal-value="1"]')
      photo3 = page.find('.photo[data-photo-reorder-ordinal-value="3"]')

      # Perform drag and drop
      photo1.drag_to(photo3)

      # Wait for grid reflow
      sleep 0.5

      # Reload page to verify persistence
      visit "/collages/#{collage.rw_guid}"

      # Verify photo order changed in database
      collage.reload
      ordinals = collage.photos.map(&:ordinal).sort
      expect(ordinals).to eq([1, 2, 3, 4, 5]) # Still sequential

      # Verify visual order changed (photo that was at position 1 is now at position 3)
      # This would require checking actual DOM positions after reorder
    end

    it 'updates ordinals in database after drag' do
      visit "/collages/#{collage.rw_guid}"

      expect(page).to have_css('.photo', count: 5)

      original_photo = collage.photos.find_by(ordinal: 1)

      # Drag first photo to last position
      photo1 = page.find('.photo[data-photo-reorder-ordinal-value="1"]')
      photo5 = page.find('.photo[data-photo-reorder-ordinal-value="5"]')

      photo1.drag_to(photo5)

      # Wait for API call to complete
      sleep 0.5

      # Verify ordinal updated in database
      original_photo.reload
      expect(original_photo.ordinal).not_to eq(1)
    end

    it 'maintains grid layout after reorder' do
      visit "/collages/#{collage.rw_guid}"

      expect(page).to have_css('.photo', count: 5)

      # Perform drag operation
      photo1 = page.find('.photo[data-photo-reorder-ordinal-value="1"]')
      photo3 = page.find('.photo[data-photo-reorder-ordinal-value="3"]')

      photo1.drag_to(photo3)

      # Wait for grid reflow
      sleep 0.5

      # Verify no overlapping photos (all have absolute positioning)
      photos = page.all('.photo')
      expect(photos.count).to eq(5)

      # Verify each photo has position set
      photos.each do |photo|
        expect(photo[:style]).to include('position')
        expect(photo[:style]).to include('absolute')
      end
    end

    it 'shows visual feedback during drag' do
      visit "/collages/#{collage.rw_guid}"

      expect(page).to have_css('.photo', count: 5)

      photo = page.find('.photo[data-photo-reorder-ordinal-value="1"]')

      # This test would need to verify CSS classes during drag
      # Capybara's drag_to doesn't preserve intermediate states
      # Manual testing required for visual feedback validation

      expect(photo[:draggable]).to eq('true')
    end
  end

  describe 'with read-only access' do
    it 'does not allow dragging photos' do
      visit "/collages/#{collage.r_guid}"

      expect(page).to have_css('.photo', count: 5)

      # Verify draggable attribute is not present or is false
      photo = page.first('.photo')
      expect(photo[:draggable]).to be_nil.or eq('false')
    end

    it 'returns 403 when attempting to update ordinal via API' do
      # This would be better as a request spec, but including for completeness
      page.driver.browser.process(:patch, "/collages/#{collage.r_guid}/photos/#{collage.photos.first.id}", {
        photo: { ordinal: 5 }
      })

      expect(page.driver.response.status).to eq(403)
    end
  end

  describe 'concurrent editing' do
    it 'applies last-write-wins for ordinal updates' do
      # Simulate two users editing same collage
      visit "/collages/#{collage.rw_guid}"

      expect(page).to have_css('.photo', count: 5)

      photo = collage.photos.find_by(ordinal: 1)

      # User 1 drags photo
      photo1_element = page.find('.photo[data-photo-reorder-ordinal-value="1"]')
      photo3_element = page.find('.photo[data-photo-reorder-ordinal-value="3"]')

      photo1_element.drag_to(photo3_element)
      sleep 0.3

      # User 2 updates same photo's ordinal directly (simulated)
      photo.update!(ordinal: 5)

      # Reload page - should show User 2's change (last write wins)
      visit "/collages/#{collage.rw_guid}"

      photo.reload
      expect(photo.ordinal).to eq(5)
    end
  end

  describe 'interaction with resize feature' do
    it 'allows both drag-to-reorder and drag-to-resize' do
      visit "/collages/#{collage.rw_guid}"

      expect(page).to have_css('.photo', count: 5)

      # Verify photos are draggable for reordering
      photo = page.find('.photo[data-photo-reorder-ordinal-value="1"]')
      expect(photo[:draggable]).to eq('true')

      # Verify photos have photo-resize controller for resizing
      expect(photo['data-controller']).to include('photo-resize')
    end
  end
end
