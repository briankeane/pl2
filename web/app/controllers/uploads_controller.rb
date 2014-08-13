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

  def process_song_without_echonest_id
    result = PL::ProcessSongWithoutEchonestId.run(params[:upload])
    render :json => result
  end

  def get_song_match_possibilities
    result = PL::GetSongMatchPossibilities.run({ artist: params[:artist],
                                                title: params[:title] })
    render :json => result
  end
  
  def delete_unprocessed_song
    result = PL::DeleteUnprocessedSong.run(params[:key])
    return result
  end
end
