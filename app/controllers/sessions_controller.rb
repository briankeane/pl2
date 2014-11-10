require 'twitter'
require 'pry-byebug'

class SessionsController < ApplicationController
  

  def create_with_twitter
    auth = request.env['omniauth.auth']
    
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = TWITTER_KEYS['CONSUMER_KEY']
      config.consumer_secret     = TWITTER_KEYS['CONSUMER_SECRET']
      config.access_token        = auth.extra.access_token.params[:oauth_token]
      config.access_token_secret = auth.extra.access_token.params[:oauth_token_secret]
    end

    begin
      user = client.user.attrs    # so we're only making one API call
      set_twitter_friend_ids(client.friend_ids.attrs[:ids])
    rescue Twitter::Error::TooManyRequests => error
      sleepy_time = error.rate_limit.reset_in
      puts "Sleeping for #{sleepy_time} secs ...."
      sleep sleepy_time
      retry
    end

    #format profile pic string for original size
    user[:profile_image_url].slice!('_normal')

    result = PL::SignInWithTwitter.run({ twitter: auth["info"]["nickname"], 
                                          twitter_uid: auth['uid'].to_s,
                                          profile_image_url: user[:profile_image_url] })
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
