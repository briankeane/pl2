require 'spec_helper'

describe 'a commercial' do
  it 'is created with an id, sponsor_id, duration, key' do
    commercial = PL::Commercial.new({ id: 1, sponsor_id: 12,
                      duration: 10000,
                      key: 'ThisIsAKey.mp3',
                      created_at: Time.new(1970),
                      updated_at: Time.new(1970, 1, 2) })
    expect(commercial.id).to eq(1)
    expect(commercial.sponsor_id).to eq(12)
    expect(commercial.duration).to eq(10000)
    expect(commercial.key).to eq('ThisIsAKey.mp3')
    expect(commercial.created_at).to eq(Time.new(1970))
    expect(commercial.updated_at).to eq(Time.new(1970, 1, 2))
  end
end