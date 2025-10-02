require 'spec_helper'

RSpec.describe 'Homepage', type: :system do
  # Migrated from features/root.feature
  # Original scenario: "I can create a collage from the homepage"

  it 'displays collage creation form' do
    visit root_path

    expect(page).to have_content('Create a Collaged')
    expect(page).to have_field('Title')
  end

  it 'allows creating a new collage', js: true do
    visit root_path

    fill_in 'Title', with: 'My Test Collage'
    click_button 'Create Collaged'

    expect(page).to have_content('My Test Collage')
  end
end
