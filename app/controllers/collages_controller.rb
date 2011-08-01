class CollagesController < ApplicationController
  def create
    respond_to do |format|
      if collage = Collage.create(params[:collage])
        format.json { render json: collage }
      else
        format.json { render json: collage.errors, code: 422 }
      end
    end
  end
end
