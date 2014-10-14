class ListensController < ApplicationController
  def index
    @current_schedule = current_schedule
    binding.pry
  end
end
