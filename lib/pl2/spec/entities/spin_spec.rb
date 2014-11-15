require 'spec_helper'

describe 'a spin' do
  before (:each) do
    @song = PL.db.create_song({ title: 'song', duration: 2000 })
    @commercial = PL.db.create_commercial({ duration: 1000, sponsor_id: 1})
    @commentary = PL.db.create_commentary({ duration: 3000 })


    @spin = PL::Spin.new({ id: 1, 
                          schedule_id: 3,
                          current_position: 2, 
                          audio_block_id: @song.id,
                          created_at: Time.new(1970),
                          updated_at: Time.new(1970, 1, 2),
                          airtime: Time.new(2014,1,1, 12) })
    @spin2 = PL::Spin.new({ id: 1, 
                          schedule_id: 3,
                          current_position: 3, 
                          audio_block_id: @commercial.id,
                          created_at: Time.new(1970),
                          updated_at: Time.new(1970, 1, 2),
                          airtime: 4000 })
    @spin3 = PL::Spin.new({ id: 1, 
                          schedule_id: 3,
                          current_position: 4,
                          audio_block_id: @commentary.id,
                          created_at: Time.new(1970),
                          updated_at: Time.new(1970, 1, 2),
                          airtime: 4000 })
  end
    
  it 'is created with an id, current_position, audio_block_id' do
    expect(@spin.id).to eq(1)
    expect(@spin.current_position).to eq(2)
    expect(@spin.audio_block.id).to eq(@song.id)
    expect(@spin.created_at).to eq(Time.new(1970))
    expect(@spin.updated_at).to eq(Time.new(1970, 1, 2))
    expect(@spin.schedule_id).to eq(3)
    expect(@spin.airtime.to_s).to eq('2014-01-01 12:00:00 -0600')
  end

  it "grabs the audio_block if it's a song" do
    expect(@spin.audio_block.title).to eq('song')
    expect(@spin.audio_block.duration).to eq(2000)
  end
  it "grabs the audio_block if it's a commercial" do
    expect(@spin2.audio_block.sponsor_id).to eq(1)
    expect(@spin2.audio_block.duration).to eq(1000)
  end
  it "grabs the audio_block if it's a commentary" do
    expect(@spin3.audio_block.id).to eq(@commentary.id)
    expect(@spin3.audio_block.duration).to eq(3000)
  end

  it 'returns the proper duration' do
    expect(@spin.duration).to eq(2000)
    expect(@spin2.duration).to eq(1000)
    expect(@spin3.duration).to eq(3000)
  end

  it 'calculates the proper estimated_end_time' do
    expect(@spin.estimated_end_time.to_s).to eq('2014-01-01 12:00:02 -0600')
  end

  it 'can tell if a commercial follows' do
    spin = PL::Spin.new({ airtime: Time.new(2014,1,1, 12,01), audio_block_id: @song.id })
    expect(spin.commercials_follow?).to eq(false)
    spin.airtime = Time.new(2014,1,1, 11,59,59)
    expect(spin.commercials_follow?).to eq(true)
  end
end