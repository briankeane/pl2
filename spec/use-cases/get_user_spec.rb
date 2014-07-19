require 'spec_helper'

describe 'GetUser' do
  it 'calls bullshit if the user does not exist' do
    result = PL::GetUser.run(999)
    
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'gets a user' do
    user = PL.db.create_user({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                        })
    result = PL::GetUser.run(user.id)

    expect(result.success?).to eq(true)
    expect(result.user.id).to eq(user.id)
    expect(result.user.twitter).to eq('bob')
    expect(result.user.twitter_uid).to eq('5')
    expect(result.user.email).to eq('bob@bob.com')
    expect(result.user.birth_year).to eq(1977)
    expect(result.user.gender).to eq('male')
    expect(result.user.created_at).to be_a(Time)
    expect(result.user.updated_at).to be_a(Time)
  end



end