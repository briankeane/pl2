class SongsController < ApplicationController
  def index
  end

  def show
  end

  def get_songs_by_keywords
    songs = PL.db.get_songs_by_keywords(params[:searchString])
    render :json => songs
  end
end
