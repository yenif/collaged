class RootController < ApplicationController
  def index
    # Root page - show new collage form
    render 'collages/new'
  end
end
