class UploadsController < ApplicationController
  
  def new
    @filepicker_api_key = FILEPICKER_KEYS['API_KEY']
    
    result = PL::GetAllSongs.run
    @all_songs = result.all_songs
  end

  def process_song
    result = PL::ProcessSong.run(params[:upload][:key])
    result[:filename] = params[:upload][:filename]

    render :json => result
  end

  def process_song_without_song_pool
  end
end