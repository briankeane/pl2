require_relative 'auth.rb'
require_relative 'songs.rb'
require_relative 'users.rb'
require_relative 'stations.rb'

module API
  module V1
    class Root < Grape::API
      version "v1"
      format :json
      #error_format :json

      # load the rest of the API
      mount API::V1::Auth
      mount API::V1::Users
      mount API::V1::Songs
      mount API::V1::Stations
    end
  end
end