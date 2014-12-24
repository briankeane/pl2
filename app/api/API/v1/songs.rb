# SONGS methods api
# /all -- gets all songs
# /:id  -- gets a song


module API
  module V1
    class Songs < Grape::API
      # /api/users
      version "v1"
      format :json
      
      resource :songs do

        desc "get all songs"
        get :all do
          PL.db.get_all_songs
        end


        desc "get a song"
        params do
          requires :id, type: Integer, desc: "Status id."
        end
        route_param :id do
          get do
            result = PL::GetSong.run(params[:id])
            if result.success?
              result.song
            else
              error!(result.error.to_s, 404)
            end
          end
        end


      end
    end
  end
end