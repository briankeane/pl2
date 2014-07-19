class UsersController < ApplicationController
  def update
    result = PL::UpdateUser.run({ id: current_user.id,
                                  birth_year: params[:birth_year],
                                  gender: params[:gender],
                                  zipcode: params[:zipcode] })

    render :json => { result: result }
  end

  def delete
  end

  def show
  end
end
