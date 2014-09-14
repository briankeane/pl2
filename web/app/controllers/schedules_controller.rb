class SchedulesController < ApplicationController
  def move_spin
    result = PL::MoveSpin.run({ new_position: params[:newPosition],
                                old_position: params[:oldPosition],
                                schedule_id: current_schedule.id })

    render :json => result
    


  end

  def add_spin
  end

  def remove_spin
  end
end
