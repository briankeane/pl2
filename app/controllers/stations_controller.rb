class StationsController < ApplicationController
  include ApplicationHelper
  
  def dj_booth
    return redirect_to station_new_path unless current_station

    result = PL::GetProgram.run({ schedule_id: current_schedule.id })
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

    gon.audioQueue = get_audio_queue(current_schedule.id)
    gon.stationId = current_station.id
    gon.scheduleId = current_schedule.id
    
    @all_songs = PL.db.get_all_songs
  end

  def song_manager
    if !current_station || !current_station.schedule
      return redirect_to station_new_path
    end

    @spins_per_week = {}
    current_station.spins_per_week.each { |k,v| @spins_per_week[PL.db.get_song(k)] = v }

    all_songs_result = PL::GetAllSongs.run()
    @all_songs = all_songs_result.all_songs
  end

  def new
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

    current_schedule.generate_playlist(Time.now + (24*60*60))

    @first_visit = true

    render listens_index_path
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
     
     commercial_block_as_hash = result.commercial_block.to_hash   
    
     # format time
    commercial_block_as_hash["airtimeForDisplay"] = time_formatter(commercial_block_as_hash[:airtime].in_time_zone(current_station.timezone))
    commercial_block_as_hash["currentPosition"] = commercial_block_as_hash[:current_position]
    commercial_block_as_hash["key"] = "https://s3-us-west-2.amazonaws.com/playolacommercialblocks/" + result.commercial_block
    render :json => commercial_block_as_hash  
  end
end
