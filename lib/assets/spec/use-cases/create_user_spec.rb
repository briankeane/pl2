require 'spec_helper'

describe 'CreateUser' do
  it 'calls bullshit if the user already exists' do
    PL.db.create_user({ twitter: "bob" })
    result = PL::CreateUser.run({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                         })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:user_already_exists)
  end

  it 'calls bullshit if no twitter is provided' do
    result = PL::CreateUser.run({ twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                         })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_twitter_provided)
  end

  it 'calls bullshit if no twitter_uid is provided' do
    result = PL::CreateUser.run({ twitter: 'bob',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                         })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_twitter_uid_provided)
  end

  it 'calls bullshit if no email is provided' do
    result = PL::CreateUser.run({ twitter: 'bob',
                        twitter_uid: 5,
                        birth_year: 1977,
                        gender: 'male'
                         }) 
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_email_provided)
  end

  it 'calls bullshit if no birth_year is provided' do
    result = PL::CreateUser.run({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        gender: 'male'
                         })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_birth_year_provided)
  end
  it 'calls bullshit if no gender is provided' do
    result = PL::CreateUser.run({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977
                         }) 
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_gender_provided)
  end
  it 'creates a user' do
    result = PL::CreateUser.run({ twitter: 'bob',
                        twitter_uid: '5',
                        email: 'bob@bob.com',
                        birth_year: 1977,
                        gender: 'male'
                         })
    expect(result.success?).to eq(true)
    expect(result.user.twitter).to eq(PL.db.get_user(result.user.id).twitter)
    expect(result.user.twitter_uid).to eq('5')
    expect(result.user.email).to eq('bob@bob.com')
    expect(result.user.birth_year).to eq(1977)
    expect(result.user.created_at).to be_a(Time)
    expect(result.user.updated_at).to be_a(Time)
    expect(result.user.gender).to eq('male')
  end

end