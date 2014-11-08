require 'spec_helper'

describe 'SignInWithTwitter' do
  before(:all) do
    PL.db.clear_everything
  end

  it "creates a user if they don't exist yet" do
    result = PL::SignInWithTwitter.run({ twitter: "123", twitter_uid: 456 })
    expect(result.success?).to eq(true)
    expect(result.new_user).to eq(true)
    expect(result.user.twitter_uid).to eq(456)
    expect(result.user.id).to_not be_nil
    expect(result.session_id).to_not be_nil
  end

  it "signs in a user if they do exist" do
    user = PL.db.create_user({ twitter: "Bob" })
    result = PL::SignInWithTwitter.run({ twitter: "Bob" })
    expect(result.success?).to eq(true)
    expect(result.new_user).to eq(false)
    expect(result.user.id).to eq(user.id)
    expect(result.session_id).to_not be_nil
  end
end