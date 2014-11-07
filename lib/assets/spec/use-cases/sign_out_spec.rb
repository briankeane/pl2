require 'spec_helper'

describe 'SignOut' do
  it "signs out a user" do
    session_id = PL.db.create_session(5)
    PL::SignOut.run(session_id)
    expect(PL.db.get_uid_by_sid(session_id)).to be_nil
  end
end