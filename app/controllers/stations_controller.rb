class StationsController < ApplicationController
  include ApplicationHelper
  
  def index
    return redirect_to root_path unless signed_in?
    return redirect_to station_new_path unless current_station
    @current_station = current_station
    @top_stations = PL::GetTopStations.run().top_stations
    presets = PL.db.get_presets(current_user.id)
    @preset_stations = presets.map { |station_id| PL.db.get_station(station_id) }
  end

  def show
    return redirect_to root_path unless signed_in?
    return redirect_to station_new_path unless current_station
    # grab info for view
    @listen_station = PL.db.get_station(params[:id].to_i)
    @listen_user = PL.db.get_user(@listen_station.user_id)
    @log = PL.db.get_recent_log_entries({ station_id: @listen_station.id,
                                                    count: 10 })

    
    # load audioQueue array
    gon.audioQueue = get_audio_queue(@listen_station.id)

    @current_station = current_station
    gon.currentStation = current_station
    gon.stationId = @listen_station.id

    @current_user = current_user
    gon.currentUser = current_user
    @current_user_presets = PL.db.get_presets(current_user.id)
    gon.currentUserPresets = @current_user_presets
    # grab the 10 most recent songs
    @log = PL.db.get_recent_log_entries({ station_id: @listen_station.id, count: 30 })
    @log.shift  # get rid of now_playing
    @log.select! { |log_entry| log_entry.audio_block.is_a?(PL::Song)}
    @log = @log[0..9] unless (@log.size < 10)
  end

  def dj_booth
    return redirect_to root_path unless signed_in?
    return redirect_to station_new_path unless current_station

    result = PL::GetProgram.run({ station_id: current_station.id })
    @program = result.program unless !result.success?

    # remove 'now playing' from program
    @program.shift
    
    # format for local station time
    @program.each do |spin|
      spin.airtime = spin.airtime.in_time_zone(current_station.timezone)
    end

    # set first_current_position if commercial block is first
    if @program.last.is_a?(PL::CommercialBlock)
      @first_current_position = @program[1].current_position
    else
      @first_current_position = @program[0].current_position
    end

    gon.audioQueue = get_audio_queue(current_station.id)
    gon.stationId = current_station.id
    gon.stationId = current_station.id
    
    @all_songs = PL.db.get_all_songs
  end

  def song_manager
    return redirect_to root_path unless signed_in?
    return redirect_to station_new_path unless current_station

    @spins_per_week = {}
    current_station.spins_per_week.each { |k,v| @spins_per_week[PL.db.get_song(k)] = v }

    all_songs_result = PL::GetAllSongs.run()
    @all_songs = all_songs_result.all_songs
  end

  def new
    return redirect_to root_path unless signed_in?
    @songs = PL.db.get_all_songs

    # tell the browser whether or not to collect the user info
    if current_user.gender && current_user.birth_year && current_user.zipcode
      @user_info_complete = true
    else
      @user_info_complete = false
    end

    # tell the browser whether or not to collect the station info
    if !current_station
      @station_info_complete = false
    end
  end

  def create
    artists = params[:artist].values.delete_if { |artist| artist.empty? }

    result = PL::GetSongSuggestions.run(artists)

    # if the returned sample is too small, add random songs to make it
    # big enough to work with
    if result.song_suggestions.size < 54
      all_songs_result = PL::GetAllSongs.run()
      all_songs = PL.db.get_all_songs
      result.song_suggestions.each { |song| all_songs_result.all_songs.delete(song.id) }
      
      while result.song_suggestions.size < 54
        random_song = all_songs_result.all_songs.sample
        result.song_suggestions.push(random_song)
        all_songs_result.all_songs.delete(random_song.id)
      end
    end
    
    spins_per_week = {}

    result.song_suggestions[0..12].each do |song|
      spins_per_week[song.id] = PL::HEAVY_ROTATION
    end

    result.song_suggestions[13..40].each do |song|
      spins_per_week[song.id] = PL::MEDIUM_ROTATION 
    end

    result.song_suggestions[41..53].each do |song|
      spins_per_week[song.id] = PL::MEDIUM_ROTATION
    end

    result = PL::CreateStation.run({ user_id: current_user.id,
                                     spins_per_week: spins_per_week })


    current_station.generate_playlist(Time.now + (24*60*60))

    @first_visit = true

    @current_user = current_user
    gon.currentUser = current_user
    @current_user_presets = PL.db.get_presets(current_user.id)
    gon.currentUserPresets = @current_user_presets
    presets = PL.db.get_presets(current_user.id)
    @preset_stations = presets.map { |station_id| PL.db.get_station(station_id) }

    @top_stations = PL::GetTopStations.run().top_stations
    render stations_index_path
  end

  def create_spin_frequency
    case params[:spins_per_week]
    when 'Heavy'
      spins_per_week = PL::HEAVY_ROTATION
    when 'Medium'
      spins_per_week = PL::MEDIUM_ROTATION
    when 'Light'
      spins_per_week = PL::LIGHT_ROTATION
    end

    result = PL::CreateSpinFrequency.run({ spins_per_week: spins_per_week,
                                              station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end

  def update_spin_frequency
    case params[:spins_per_week]
    when 'Heavy'
      spins_per_week = PL::HEAVY_ROTATION
    when 'Medium'
      spins_per_week = PL::MEDIUM_ROTATION
    when 'Light'
      spins_per_week = PL::LIGHT_ROTATION
    end

    result = PL::UpdateSpinFrequency.run({ spins_per_week: spins_per_week,
                                              station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end

  def delete_spin_frequency
    result = PL::DeleteSpinFrequency.run({ station_id: current_station.id,
                                              song_id: params[:song_id] })
    # update station
    @current_station = result.station unless !result.success?

    render :json => result
  end

  def get_commercial_block_for_broadcast
    result = PL::GetCommercialBlockForBroadcast.run({ station_id: params[:stationId].to_i,
                                              current_position: params[:currentPosition].to_i })

    if !result.success?
      render :json => result
    end
     
    commercial_block_as_hash = result.commercial_block.to_hash   
    
     # format time
    commercial_block_as_hash["airtimeForDisplay"] = time_formatter(commercial_block_as_hash[:airtime].in_time_zone(current_station.timezone))
    commercial_block_as_hash["currentPosition"] = commercial_block_as_hash[:current_position]
    commercial_block_as_hash["key"] = "http://commercialblocks.playola.fm/" + commercial_block_as_hash[:key]
    render :json => commercial_block_as_hash  
  end

    def move_spin
    result = PL::MoveSpin.run({ new_position: params[:newPosition],
                                old_position: params[:oldPosition],
                                station_id: current_station.id })

    max_position = [params[:oldPosition], params[:newPosition]].max
    min_position = [params[:oldPosition], params[:newPosition]].min - 1  # buffer for leading commercial blocks
    
    
    result.new_program = current_station.get_program_by_current_positions({ station_id: current_station.id,
                                                                             starting_current_position: min_position,
                                                                             ending_current_position: max_position })

    result.max_position = max_position
    result.min_position = min_position

    #format airtimes
    result.new_program.map! do |spin|
      hash = spin.to_hash
      if spin.airtime
        hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      hash
    end

    render :json => result

  end

  def insert_song
    result = PL::InsertSpin.run({ station_id: current_station.id,
                                  add_position: params[:addPosition].to_i,
                                  audio_block_id: params[:songId].to_i })
    
    result.min_position = params[:addPosition].to_i - 1
    result.max_position = params[:lastCurrentPosition].to_i + 1

    result.new_program = current_station.get_program_by_current_positions({ station_id: current_station.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })
    
    # format estimated_air_times
    result.new_program.map! do |spin|
      spin_as_hash = spin.to_hash
      if spin_as_hash[:airtime]
        spin_as_hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      spin_as_hash
    end

    render :json => result
  end

  def process_commentary
    converter = PL::AudioConverter.new
    new_path = converter.wav_to_mp3(params[:data].tempfile.path)
    result = {}
    File.open(new_path, 'r') do |file|
      result = PL::ProcessCommentary.run({ audio_file: params[:data].tempfile,
                                  add_position: params[:addPosition].to_i,
                                  duration: params[:duration].to_i,
                                  station_id: current_station.id })
    end

    result.min_position = params[:addPosition].to_i - 1
    result.max_position = params[:lastCurrentPosition].to_i + 1

    result.new_program = current_station.get_program_by_current_positions({ station_id: current_station.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })
    
    # format estimated_air_times
    result.new_program.map! do |spin|
      spin_as_hash = spin.to_hash
      if spin_as_hash[:airtime]
        spin_as_hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      spin_as_hash
    end

    render :json => result
  end

  def get_spin_by_current_position
    result = PL::GetSpinByCurrentPosition.run({ station_id: params["stationId"].to_i,
                                                current_position: params["currentPosition"].to_i })
    spin_as_hash = result.spin.to_hash

    # format time
    spin_as_hash["airtimeForDisplay"] = time_formatter(spin_as_hash[:airtime].in_time_zone(current_station.timezone))
    spin_as_hash["currentPosition"] = spin_as_hash[:current_position]

    if result.spin.audio_block.is_a?(PL::Song)
      spin_as_hash["key"] = 'http://songs.playola.fm/' + result.spin.audio_block.key
      spin_as_hash["type"] = "Song"
    elsif result.spin.audio_block.is_a?(PL::Commentary)
      spin_as_hash["key"] = 'http://commentaries.playola.fm/' + result.spin.audio_block.key
      spin_as_hash["type"] = "Commentary"
    end

    render :json => spin_as_hash
  end


  def remove_spin
    result = PL::RemoveSpin.run({ station_id: current_station.id,
                                   current_position: params[:current_position] })
    if result.success?
      result.min_position = params[:current_position] - 1
      result.max_position = params[:last_current_position].to_i + 1
      result.new_program = current_station.get_program_by_current_positions({ station_id: current_station.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })

      # format estimated_air_times
      result.new_program.map! do |spin|
        spin_as_hash = spin.to_hash
        if spin.airtime
          spin_as_hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
        end
        spin_as_hash
      end
      render :json => result
    end
  end

  def reset_station
    result = PL::ClearStation.run(current_station.id)

    # run GetProgram to repopulate the beginning of the station
    result = PL::GetProgram.run({ station_id: current_station.id })

    render :json => { success: true }
  end
end
