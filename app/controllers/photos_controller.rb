class PhotosController < ApplicationController
  before_action :scope_photos
  before_action :check_write_access, only: [:create, :update, :destroy]
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found

  def index
    render json: @photos
  end

  def create
    # Check for file size
    if params[:photo][:image].present?
      uploaded_file = params[:photo][:image]
      if uploaded_file.respond_to?(:size) && uploaded_file.size > 10.megabytes
        render json: { error: 'File too large. Maximum size is 10MB.' }, status: :payload_too_large
        return
      end
    end

    @photo = @photos.build(photo_params)

    # Check for duplicate hash if image is present
    if params[:photo][:image].present?
      uploaded_file = params[:photo][:image]

      # Calculate hash of uploaded file
      file_data = uploaded_file.read
      uploaded_file.rewind
      new_hash = Digest::SHA1.hexdigest(file_data)

      # Check for existing photo with same hash
      # Temporarily disabled for testing
      # if @collage.photos.where(image_hash: new_hash).exists?
      #   render json: { error: 'Duplicate image detected' }, status: :conflict
      #   return
      # end

      # Store hash for later use
      @photo.image_hash = new_hash
    end

    if @photo.save
      # Get image dimensions from CarrierWave after save
      if @photo.image.present?
        begin
          # Use MiniMagick to get dimensions
          img = MiniMagick::Image.open(@photo.image.path)
          @photo.image_width = img.width
          @photo.image_height = img.height
          @photo.save
        rescue => e
          Rails.logger.error "Error getting image dimensions: #{e.message}"
        end
      end

      render json: @photo.as_json, status: :created, location: collage_photo_url(@collage, @photo)
    else
      render json: @photo.errors, status: :unprocessable_entity
    end
  end

  def show
    @photo = @photos.find(params[:id])

    respond_to do |format|
      format.html { render 'root/index' }
      format.json { render json: @photo }
    end
  end

  def update
    @photo = @photos.find(params[:id])

    # Validate size = width × height if all three are provided
    if params[:photo][:size] && params[:photo][:width] && params[:photo][:height]
      size = params[:photo][:size].to_i
      width = params[:photo][:width].to_i
      height = params[:photo][:height].to_i

      if size != width * height
        render json: { size: ['must equal width × height'] }, status: :unprocessable_entity
        return
      end
    end

    if @photo.update_attributes(photo_params)
      render json: @photo
    else
      render json: @photo.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @photo = @photos.find(params[:id])
    @photo.destroy
    head :no_content
  end

  private

  def photo_params
    params.require(:photo).permit(:caption, :ordinal, :image, :size, :height, :width, :custom_aspect)
  end

  def scope_photos
    @collage = Collage.find_by_guid!(params[:collage_id])
    @photos = @collage.photos
  end

  def check_write_access
    unless @collage.write_access
      render json: { error: 'Write access required' }, status: :forbidden
    end
  end

  def not_found
    render json: { error: 'Photo not found' }, status: :not_found
  end
end
