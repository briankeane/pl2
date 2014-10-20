require 'twitter'

class SessionsController < ApplicationController
  

  def create_with_twitter
    auth = request.env['omniauth.auth']
    

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = TWITTER_KEYS['CONSUMER_KEY']
      config.consumer_secret     = TWITTER_KEYS['CONSUMER_SECRET']
      config.access_token        = auth.extra.access_token.params[:oauth_token]
      config.access_token_secret = auth.extra.access_token.params[:oauth_token_secret]
    end

    friends_names = client.friends.to_a.map { |friend| friend.screen_name }

    binding.pry





    result = PL::SignInWithTwitter.run({ twitter: auth["info"]["nickname"], twitter_uid: auth['uid'].to_s })
    if result.success?
      if result.new_user
        session[:pl_session_id] = result.session_id
        redirect_to station_new_path
      else
        session[:pl_session_id] = result.session_id
        return redirect_to dj_booth_path
      end
    else
      redirect_to sign_in_path
    end
  end


  def destroy
    reset_session
    PL::SignOut.run(session[:pl_session_id])
    return redirect_to root_path
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

end
