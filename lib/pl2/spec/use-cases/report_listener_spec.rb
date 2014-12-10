require 'spec_helper'

describe 'ReportListener' do

  it 'calls bullshit if the station is not found' do
    result = PL::ReportListener.run({ station_id: 9999,
                                      user_id: 12,
                                      current_position: 12 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:station_not_found)
  end

  it 'calls bullshit if the user is not found' do
    station = PL.db.create_station({ user_id: 1 })
    result = PL::ReportListener.run({ station_id: station.id,
                                        user_id: 7,
                                        current_position: 12 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end


  describe 'more ReportListener' do
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
                                                end_time: Time.new(2014,1,1,15) })
      end
    end

    it 'creates a new listening session' do
      Timecop.freeze(2014,1,1, 13)
      result = PL::ReportListener.run({ station_id: @station.id,
                                        user_id: @user.id })
      expect(result.success?).to eq(true)
      expect(result.listening_session.start_time.to_s).to eq(Time.new(2014,1,1, 13).to_s)
      expect(result.listening_session.end_time.to_s).to eq(Time.new(2014,1,1, 13,2).to_s)
      expect(PL.db.get_listener_count({ station_id: @station.id })).to eq(11)
    end

    it 'updates a previously opened listening session' do
      PL.db.create_listening_session({ station_id: @station.id,
                                        user_id: @user.id,
                                        starting_current_position: 14,
                                        ending_current_position: 14,
                                        start_time: Time.new(2014,1,1, 12,59),
                                        end_time: Time.new(2014,1,1, 13) })
      
      Timecop.freeze(2014,1,1, 13)
      result = PL::ReportListener.run({ station_id: @station.id,
                                        user_id: @user.id,
                                        current_position: 15 })
      expect(result.success?).to eq(true)
      expect(result.listening_session.start_time.to_s).to eq(Time.new(2014,1,1, 12,59).to_s)
      expect(result.listening_session.end_time.to_s).to eq(Time.new(2014,1,1, 13,2).to_s)
      expect(PL.db.get_listener_count({ station_id: @station.id })).to eq(11)
    end


    after(:each) do
      Timecop.return
    end
  end
end