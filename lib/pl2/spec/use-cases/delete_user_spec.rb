require 'spec_helper'

describe 'DeleteUser' do
  it 'calls bullshit if the user is not found' do
    result = PL::DeleteUser.run(5)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'gets a user by twitter' do
    user = PL.db.create_user({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                        })
    result = PL::DeleteUser.run(user.id)

    expect(result.success?).to eq(true)
    expect(result.user.id).to eq(user.id)
    expect(PL.db.get_user(result.user.id)).to be_nil
  end
end