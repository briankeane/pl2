class ApplicationController < ActionController::Base
  helper_method :signed_in?

  def signed_in?
    false
  end

  protect_from_forgery with: :exception
end
