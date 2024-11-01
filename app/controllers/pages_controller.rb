require 'cdsg.rb'

class PagesController < ApplicationController
  def home
    if page_params[:quit] == "true"
      flash[:notice] = "You quit the game. This is a decidedly human action."
    end
  end

  private
  
  def page_params
    params.permit(:quit)
  end
end
