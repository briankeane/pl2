module API
  module V1
    class Users < Grape::API
      # /api/users
      resource :users do

        #
        # auth code goes here!
        #

        desc 'Returns pong'
        get :ping do
          { message: 'pong' }
        end
      end
    end
  end
end