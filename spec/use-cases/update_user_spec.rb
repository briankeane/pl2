require 'spec_helper'

describe 'UpdateUser' do
  it 'calls bullshit if the user is not found' do
    result = PL::UpdateUser.run({ id: 99999,
                          secs_of_commercial_per_hour: 1 })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_not_found)
  end

  it 'updates the user' do
    user = PL.db.create_user({ twitter: 'Bob' })
    result = PL::UpdateUser.run({ id: user.id,
                                zipcode: '123456',
                                gender: 'male',
                                birth_year: '2000' })
    expect(result.success?).to eq(true)
    expect(result.user.id).to eq(user.id)
    expect(result.user.zipcode).to eq('123456')
    expect(result.user.gender).to eq('male')
    expect(result.user.birth_year).to eq('2000')
  end
end
