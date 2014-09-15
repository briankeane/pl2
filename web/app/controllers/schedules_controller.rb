class SchedulesController < ApplicationController
  include ApplicationHelper

  def move_spin
    result = PL::MoveSpin.run({ new_position: params[:newPosition],
                                old_position: params[:oldPosition],
                                schedule_id: current_schedule.id })

    max_position = [params[:oldPosition], params[:newPosition]].max
    min_position = [params[:oldPosition], params[:newPosition]].min

    result.new_program = current_schedule.get_program_by_current_positions({ schedule_id: current_schedule.id,
                                                                             starting_current_position: min_position,
                                                                             ending_current_position: max_position })

    result.max_position = max_position
    result.min_position = min_position

    # format estimated_air_times
    result.new_program.each do |spin|
      if spin.estimated_airtime
        spin.estimated_airtime = time_formatter(spin.estimated_airtime.in_time_zone(current_station.timezone))
      end
    end

    render :json => result

  end

  def add_spin
  end

  def remove_spin
  end
end
