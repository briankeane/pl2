class UsersController < ApplicationController
  def update
    timezone_finder = PL::TimezoneFinder.new
    timezone = timezone_finder.find_by_zip(params[:zipcode])
    result = PL::UpdateUser.run({ id: current_user.id,
                                  birth_year: params[:birth_year],
                                  gender: params[:gender],
                                  zipcode: params[:zipcode],
                                  timezone: timezone })

    render :json => { result: result }
  end

  def delete
  end

  def show
  end

  def report_listener
    binding.pry
    result = PL::ReportListener.run({ station_id: params[:stationId],
                                      user_id: current_user.id })

    render :json => result
  end
end
