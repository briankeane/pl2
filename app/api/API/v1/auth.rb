module API 
  module V1 
    class Auth < Grape::API
      # /api/auth
      version "v1"
      format :json
      
      resource :auth do

        #
        # auth code goes here!
        #

        desc 'Returns pong if logged in correctly.'
        params do
          requires :token, type: String, desc: 'Access token.'
        end
        get :ping do
          authenticate!
          { message: 'pong' }
        end
      end
    end
  end
end