class SessionsController < ApplicationController
  

  def create_with_twitter
    auth = request.env['omniauth.auth']
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
