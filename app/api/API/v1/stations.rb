require_relative 'helpers/api_helpers.rb'

module API
  module V1
    class Stations < Grape::API
      # /api/users
      version "v1"
      format :json
      
      resource :stations do
        desc "Return an audioQueue"
        get :get_audio_queue do
          now_playing = PL::GetProgramForBroadcast.run({ station_id: params[:stationId].to_i }).program

          # 'touch' audio_blocks
          now_playing.each { |log| log.audio_block unless log.is_a?(PL::CommercialBlock) }

          formatted_station = now_playing.map do |spin|
            obj = {}
            case
            when spin.is_a?(PL::CommercialBlock)
              obj[:type] = 'CommercialBlock'
              obj[:key] = 'http://commercialblocks.playola.fm/' + spin.key
            when spin.audio_block.is_a?(PL::Song)
              obj[:type] = 'Song'
              obj[:key] = 'http://songs.playola.fm/' + spin.audio_block.key
              obj[:artist] = spin.audio_block.artist
              obj[:title] = spin.audio_block.title
              obj[:id] = spin.audio_block.id
            when spin.audio_block.is_a?(PL::Commentary)
              obj[:type] = 'Commentary'
              obj[:key] = 'http://commentaries.playola.fm/' + spin.audio_block.key
            end

            obj[:currentPosition] = spin.current_position
            obj[:commercialsFollow?] = spin.commercials_follow?
            obj[:airtime_in_ms] = spin.airtime_in_ms
            
            obj
          end

          formatted_station
        end

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

        desc 'Gets a Spin by Current Position'
        get :get_spin_by_current_position do
          result = PL::GetSpinByCurrentPosition.run({ station_id: params["stationId"].to_i,
                                                current_position: params["currentPosition"].to_i })
    
          if !result.spin
            return result
          end

          spin_as_hash = result.spin.to_hash

          current_station = PL.db.get_station(params["stationId"].to_i)

          # format time
          spin_as_hash["airtimeForDisplay"] = ApiHelpers.time_formatter(spin_as_hash[:airtime].in_time_zone(current_station.timezone))
          spin_as_hash["currentPosition"] = spin_as_hash[:current_position]

          if result.spin.audio_block.is_a?(PL::Song)
            spin_as_hash["key"] = 'http://songs.playola.fm/' + result.spin.audio_block.key
            spin_as_hash["type"] = "Song"
          elsif result.spin.audio_block.is_a?(PL::Commentary)
            spin_as_hash["key"] = 'http://commentaries.playola.fm/' + result.spin.audio_block.key
            spin_as_hash["type"] = "Commentary"
          end

          spin_as_hash
        end

        desc "Return a status."
        params do
          requires :id, type: Integer, desc: "Status id."
        end
        route_param :id do
          get do
            PL.db.get_station(params[:id])
          end
        end

      end
    end
  end
end