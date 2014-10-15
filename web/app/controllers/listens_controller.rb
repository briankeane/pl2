class ListensController < ApplicationController
  def index
    @current_schedule = current_schedule
  end
end
