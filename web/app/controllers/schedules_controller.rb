class SchedulesController < ApplicationController
  include ApplicationHelper

  def move_spin
    result = PL::MoveSpin.run({ new_position: params[:newPosition],
                                old_position: params[:oldPosition],
                                schedule_id: current_schedule.id })

    max_position = [params[:oldPosition], params[:newPosition]].max
    min_position = [params[:oldPosition], params[:newPosition]].min - 1  # buffer for leading commercial blocks
    

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

  def insert_song
    result = PL::InsertSpin.run({ schedule_id: current_schedule.id,
                                  add_position: params[:addPosition].to_i,
                                  audio_block_id: params[:songId].to_i })
    
    result.min_position = params[:addPosition].to_i - 1
    result.max_position = params[:lastCurrentPosition].to_i + 1

    result.new_program = current_schedule.get_program_by_current_positions({ schedule_id: current_schedule.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })
    
    # format estimated_air_times
    result.new_program.each do |spin|
      if spin.estimated_airtime
        spin.estimated_airtime = time_formatter(spin.estimated_airtime.in_time_zone(current_station.timezone))
      end
    end


    render :json => result
  end

  def process_commentary
    converter = PL::AudioConverter.new
    new_path = converter.wav_to_mp3(params[:data].tempfile.path)
    result = {}
    File.open(new_path, 'r') do |file|
      result = PL::ProcessCommentary.run({ audio_file: params[:data].tempfile,
                                  add_position: params[:addPosition].to_i,
                                  duration: params[:duration],
                                  schedule_id: current_schedule.id })
    end

    result.min_position = params[:addPosition].to_i - 1
    result.max_position = params[:lastCurrentPosition].to_i + 1

    result.new_program = current_schedule.get_program_by_current_positions({ schedule_id: current_schedule.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })
    
    # format estimated_air_times
    result.new_program.each do |spin|
      if spin.estimated_airtime
        spin.estimated_airtime = time_formatter(spin.estimated_airtime.in_time_zone(current_station.timezone))
      end
    end

    render :json => result
  end

  def get_spin_after_next
    spin = current_schedule.get_spin_after_next
    render :json spin
  end


  def remove_spin
  end
end
