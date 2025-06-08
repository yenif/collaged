class PhotosController < ApplicationController
  before_action :scope_photos
  def index
    respond_to do |format|
      format.json { render json: @photos }
    end
  end

  def create
    respond_to do |format|
      if @photo = @photos.create(params[:photo])
        format.json { render json: @photo, status: :created, location: url_for([@collage,@photo]) }
      else
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
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
    respond_to do |format|
      if @photo.update(photo_params)
        format.json { render json: @photo }
      else
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  protected
  def scope_photos
    @collage = Collage.find_by_guid!(params[:collage_id])
    @photos = @collage.photos
  end
end


private

  private


  private

  def photo_params
    params.require(:photo).permit(:caption, ordinal, image, size, height, width, custom_aspect, :image, :image_cache)
  end
