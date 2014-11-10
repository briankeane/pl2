require 'spec_helper'

describe 'StoreTwitterFriendsStations' do
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
    result = PL::StoreTwitterFriendStations.run({ user_id: 9999, friend_ids: [1,2,3,4,5,6] })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'takes in an array of twitter_ids and returns an array of existing stations' do
    following_user = PL.db.create_user({ twitter: 'Bob' })
    result = PL::StoreTwitterFriendStations.run({ user_id: following_user.id,
                                                  friend_ids: [9999,99998,99997,999996,99995, @users[0].twitter_uid, @users[1].twitter_uid, @users[2].twitter_uid] })
    ids = result.followed_stations_list.map { |station| station.id }
    
    expect(result.success?).to eq(true)
    expect(result.followed_stations_list.size).to eq(3)
    expect(ids.include?(@stations[0].id)).to eq(true)
    expect(ids.include?(@stations[1].id)).to eq(true)
    expect(ids.include?(@stations[2].id)).to eq(true)
    expect(ids.include?(@stations[3].id)).to eq(false)
  end


end
