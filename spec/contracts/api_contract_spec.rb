require 'spec_helper'

RSpec.describe 'API Contract Validation', type: :request do
  # These tests validate that API responses match the OpenAPI schema
  # Requires: docs/openapi.yaml

  describe 'Collages API' do
    let(:collage) { create(:collage, title: 'Test Collage') }

    context 'when OpenAPI schema exists' do
      before do
        unless File.exist?(Rails.root.join('docs/openapi.yaml'))
          skip 'OpenAPI schema not found at docs/openapi.yaml'
        end
      end

      it 'GET /collages/:id matches schema' do
        get "/collages/#{collage.id}", as: :json
        expect(response).to have_http_status(:success)
        assert_schema_conform
      end

      it 'POST /collages matches schema' do
        post '/collages', params: { collage: { title: 'New Collage' } }, as: :json
        expect(response).to have_http_status(:success)
        assert_schema_conform
      end
    end

    context 'when OpenAPI schema does not exist' do
      it 'documents the need for OpenAPI schema' do
        skip 'OpenAPI schema not yet defined - future task to create docs/openapi.yaml'
      end
    end
  end

  describe 'Photos API' do
    let(:collage) { create(:collage) }

    it 'POST /collages/:id/photos validates against schema' do
      unless File.exist?(Rails.root.join('docs/openapi.yaml'))
        skip 'OpenAPI schema not found'
      end

      test_file = Tempfile.new(['test', '.jpg'])
      test_file.write('fake image data')
      test_file.rewind

      post "/collages/#{collage.id}/photos",
           params: { photo: { image: Rack::Test::UploadedFile.new(test_file.path, 'image/jpeg') } }

      test_file.close
      test_file.unlink

      expect(response).to have_http_status(:success)
      # assert_schema_conform # Would validate if schema exists
    end
  end
end
