module API
  module V1
    class Songs < Grape::API
      # /api/users
      resource :songs do

        desc 'Returns pong'
        get :ping do
          { message: 'pong' }
        end

        desc "Return a status."
        params do
          requires :id, type: Integer, desc: "Status id."
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