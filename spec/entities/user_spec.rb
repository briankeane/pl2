require 'spec_helper'

describe 'a user' do

  before(:each) do
    @user = PL::User.new({   id: 1,
                            twitter: 'BrianKeaneTunes',
                            twitter_uid: '756',
                            email: 'lonesomewhistle_gmail.com',
                            birth_year: 1977,
                            gender: 'male',
                            profile_image_url: 'http://badass.jpg' })
  end

  
  it 'is created with an id, twitter_uid, email, birth_year, and gender' do
    expect(@user.id).to_not be_nil
    expect(@user.twitter).to eq('BrianKeaneTunes')
    expect(@user.twitter_uid).to eq('756')
    expect(@user.birth_year).to eq(1977)
    expect(@user.gender).to eq('male')
    expect(@user.profile_image_url).to eq('http://badass.jpg')
  end

  it 'gets its station' do
    station = PL.db.create_station({ user_id: @user.id })
    expect(@user.station.id).to eq(station.id)
  end
end