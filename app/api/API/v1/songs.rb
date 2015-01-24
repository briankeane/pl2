module API
  module V1
    class Songs < Grape::API
      # /api/users
      version "v1"
      format :json
      
      resource :songs do

        desc 'Returns pong'
        get :ping do
          { message: 'pong' }
        end

        desc "Return Song Info"
        params do
          requires :id, type: Integer, desc: "Song Info"
        end
        route_param :id do
          get do
            PL.db.get_song(params[:id])
          end
        end

      end
    end
  end
end