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

    #format airtimes
    result.new_program.map! do |spin|
      hash = spin.to_hash
      if spin.airtime
        hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      hash
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
    result.new_program.map! do |spin|
      spin_as_hash = spin.to_hash
      if spin_as_hash[:airtime]
        spin_as_hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      spin_as_hash
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
                                  duration: params[:duration].to_i,
                                  schedule_id: current_schedule.id })
    end

    result.min_position = params[:addPosition].to_i - 1
    result.max_position = params[:lastCurrentPosition].to_i + 1

    result.new_program = current_schedule.get_program_by_current_positions({ schedule_id: current_schedule.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })
    
    # format estimated_air_times
    result.new_program.map! do |spin|
      spin_as_hash = spin.to_hash
      if spin_as_hash[:airtime]
        spin_as_hash[:airtimeForDisplay] = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
      end
      spin_as_hash
    end

    render :json => result
  end

  def get_spin_by_current_position
    result = PL::GetSpinByCurrentPosition.run({ schedule_id: params["scheduleId"].to_i,
                                                current_position: params["currentPosition"].to_i })
    spin_as_hash = result.spin.to_hash

    # format time
    spin_as_hash["airtimeForDisplay"] = time_formatter(spin_as_hash[:airtime].in_time_zone(current_station.timezone))
    spin_as_hash["currentPosition"] = spin_as_hash[:current_position]

    if result.spin.audio_block.is_a?(PL::Song)
      spin_as_hash["key"] = 'https://s3-us-west-2.amazonaws.com/playolasongs/' + result.spin.audio_block.key
      spin_as_hash["type"] = "Song"
    elsif result.spin.audio_block.is_a?(PL::Commentary)
      spin_as_hash["key"] = 'https://s3-us-west-2.amazonaws.com/playolacommentaries' + result.spin.audio_block.key
      spin_as_hash["type"] = "Commentary"
    end

    render :json => spin_as_hash
  end


  def remove_spin
    result = PL::RemoveSpin.run({ schedule_id: current_schedule.id,
                                   current_position: params[:current_position] })
    if result.success?
      result.min_position = params[:current_position] - 1
      result.max_position = params[:last_current_position].to_i + 1
      result.new_program = current_schedule.get_program_by_current_positions({ schedule_id: current_schedule.id,
                                                                            starting_current_position: result.min_position,
                                                                            ending_current_position: result.max_position })

      # format estimated_air_times
      result.new_program.each do |spin|
        if spin.airtime
          spin.airtime = time_formatter(spin.airtime.in_time_zone(current_station.timezone))
        end
      end
      render :json => result
    end
  end

  def reset_schedule
    result = PL::ClearSchedule.run(current_schedule.id)

    # run GetProgram to repopulate the beginning of the schedule
    result = PL::GetProgram.run({ schedule_id: current_schedule.id })

    render :json => { success: true }
  end

  def report_spin_started
  end

  def report_spin_finished
  end
end
