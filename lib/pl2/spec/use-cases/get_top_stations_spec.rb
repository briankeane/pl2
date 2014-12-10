require 'spec_helper'

describe 'GetTopStations' do

  before(:each) do
    Timecop.travel(2014,1,1, 1)
    @user = PL.db.create_user({ twitter: 'bob' })
    @station = PL.db.create_station({ user_id: 1 })
    @log_entry = PL.db.create_log_entry({ station_id: @station.id,
                                          current_position: 15,
                                          airtime: Time.new(2014,1,1, 12,59),
                                          duration: 180000 })
    @sessions = []
    10.times do |i|
      @sessions << PL.db.create_listening_session({ user_id: i+1000,
                                              station_id: @station.id,
                                              start_time: Time.new(2014,1,1,13),
                                              end_time: Time.new(2014,1,1,15),
                                              starting_current_position: 15,
                                              ending_current_position: 15 })
    end
  end

  xit 'gets the top stations overall' do
  end
end