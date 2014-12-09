require 'spec_helper'

describe 'a listening_session' do
  it 'is created with an id, listener_id, start_time, end_time, first_current_position, last_current_position' do
    session = PL::ListeningSession.new({ id: 1,
                                    starting_current_position: 2,
                                    ending_current_position: 3,
                                    start_time: Time.new(2014,1,1),
                                    end_time: Time.new(2014,1,2),
                                    listener_id: 4,
                                    station_id: 5 })
    expect(session.id).to eq(1)
    expect(session.starting_current_position).to eq(2)
    expect(session.ending_current_position).to eq(3)
    expect(session.start_time.to_s).to eq(Time.new(2014,1,1).to_s)
    expect(session.end_time).to eq(Time.new(2014,1,2).to_s)
    expect(session.listener_id).to eq(4)
    expect(session.station_id).to eq(5)
  end
end