class CollagesController < ApplicationController
  def create
    respond_to do |format|
      if @collage = Collage.create(collage_params)
        format.json { render json: @collage, status: :created, location: url_for(@collage) }
      else
        format.json { render json: @collage.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @collage = Collage.find_by_guid!(params[:id])
    respond_to do |format|
      format.html { render 'root/index' }
      format.json { render json: @collage }
    end
  end

  def update
    @collage = Collage.find_by_guid!(params[:id])
    respond_to do |format|
      if @collage.update(collage_params)
        format.json { render json: @collage }
      else
        format.json { render json: @collage.errors, status: :unprocessable_entity }
      end
    end
  end
end


private

  private


  private

  def collage_params
    params.require(:collage).permit(:title)
  end
