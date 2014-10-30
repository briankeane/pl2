class ListensController < ApplicationController
  def index
    @current_schedule = current_schedule
  end

  def show
    @listen_station = PL.db.get_station(params[:id].to_i)
    @listen_user = PL.db.get_user(@listen_station.user_id)

    station = PL.db.get_station(params[:id])
    schedule = PL.db.get_schedule(station.schedule_id)

    now_playing = PL::GetProgram.run({ schedule_id: schedule.id }).program
    
    now_playing.unshift(schedule.now_playing)

    gon.station_log = PL.db.get_recent_log_entries({ station_id: station.id,
                                                    count: 10 })

    # 'touch' audio_blocks
    gon.station_log.each { |log| log.audio_block }

    gon.schedule_id = station.schedule_id

    # load audioQueue array
    gon.audioQueue = now_playing[0..2].map do |spin|
      obj = {}
      case
      when spin.is_a?(PL::CommercialBlock)
        obj[:type] = 'CommercialBlock'
        obj[:key] = 'STUBFORCBKEY'
      when spin.audio_block.is_a?(PL::Song)
        obj[:type] = 'Song'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolasongs/' + spin.audio_block.key
        obj[:artist] = spin.audio_block.artist
        obj[:title] = spin.audio_block.title
      when spin.audio_block.is_a?(PL::Commentary)
        obj[:type] = 'Commentary'
        obj[:key] = 'https://s3-us-west-2.amazonaws.com/playolacommentaries/' + spin.audio_block.key
      end

      obj[:currentPosition] = spin.current_position
      obj[:commercialsFollow?] = spin.commercials_follow?
      if spin.is_a?(PL::LogEntry)
        obj[:airtime_in_ms] = spin.airtime_in_ms
      else
        obj[:airtime_in_ms] = spin.airtime_in_ms
      end
      obj
    end
  end
end
