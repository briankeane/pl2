require 'spec_helper'

describe 'a commentary' do
    before(:each) do
        @commentary = PL::Commentary.new({ id: 1, 
                                    schedule_id: 2,
                                    duration: 5000,
                                    key: 'ThisIsAKey.mp3' })    
    end
    
  it 'is created with an id, schedule_id, duration, key' do
    expect(@commentary.id).to eq(1)
    expect(@commentary.schedule_id).to eq(2)
    expect(@commentary.duration).to eq(5000)
    expect(@commentary.key).to eq('ThisIsAKey.mp3')
  end
end