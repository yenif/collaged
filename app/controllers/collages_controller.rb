class CollagesController < ApplicationController
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found

  def create
    @collage = Collage.new(collage_params)

    if @collage.save
      render json: collage_json(@collage), status: :created, location: collage_url(@collage)
    else
      render json: @collage.errors, status: :unprocessable_entity
    end
  end

  def show
    @collage = Collage.find_by_guid!(params[:id])

    respond_to do |format|
      format.html { render 'collages/show' }
      format.json { render json: collage_json(@collage) }
    end
  end

  def update
    @collage = Collage.find_by_guid!(params[:id])

    unless @collage.write_access
      render json: { error: 'Write access required' }, status: :forbidden
      return
    end

    if @collage.update_attributes(collage_params)
      render json: collage_json(@collage)
    else
      render json: @collage.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @collage = Collage.find_by_guid!(params[:id])

    unless @collage.write_access
      render json: { error: 'Write access required' }, status: :forbidden
      return
    end

    @collage.destroy
    head :no_content
  end

  private

  def collage_params
    params.require(:collage).permit(:title)
  end

  def collage_json(collage)
    json = {
      id: collage.to_param,
      title: collage.title,
      r_guid: collage.r_guid,
      write_access: collage.write_access
    }

    # Only include rw_guid if write access
    json[:rw_guid] = collage.rw_guid if collage.write_access

    # Include photos if present
    if collage.photos.any?
      json[:photos] = collage.photos.map { |photo| photo.as_json }
    end

    json
  end

  def not_found
    render json: { error: 'Collage not found' }, status: :not_found
  end
end
