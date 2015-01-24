module API
  module V1
    class Stations < Grape::API
      # /api/users
      version "v1"
      format :json
      
      resource :stations do

        desc 'Returns pong'
        get :ping do
          { message: 'pong' }
        end

        desc 'Gets top stations'
        get :top_stations do
          result = PL::GetTopStations.run()
          if result.success?
            return result.top_stations
          else
            return result.error
          end
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