require 'spec_helper'

describe 'GetTwitterFriendsStations' do
  before(:each) do
    @users = []
    @stations = []

    10.times do |i|
      user = PL.db.create_user({ twitter_uid: i+1 })
      station = PL.db.create_station({ user_id: user.id })
      @users << user
      @stations << station
    end
  end

  it 'calls bullshit when the user is not found' do
    result = PL::GetFollowedStations.run(9999)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'returns an array of the followed stations' do
    following_user = PL.db.create_user({ twitter: 'Bob' })
    PL.db.store_twitter_friends({ follower_uid: following_user.id,
                                followed_station_ids: [@users[0].station.id, @users[1].station.id, @users[2].station.id] })
    result = PL::GetFollowedStations.run(following_user.id)
    ids = result.followed_stations_list.map { |station| station.id }
    
    expect(result.success?).to eq(true)
    expect(result.followed_stations_list.size).to eq(3)
    expect(ids.include?(@stations[0].id)).to eq(true)
    expect(ids.include?(@stations[1].id)).to eq(true)
    expect(ids.include?(@stations[2].id)).to eq(true)
    expect(ids.include?(@stations[3].id)).to eq(false)
    expect(PL.db.get_followed_stations_list(following_user.id).size).to eq(3)
  end
end