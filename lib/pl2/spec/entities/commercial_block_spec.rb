require 'spec_helper'

describe 'a commercial_block' do
  before(:each) do
    @commercial1 = PL.db.create_commercial({})
    @commercial2 = PL.db.create_commercial({})
    @commercial_block = PL::CommercialBlock.new({ id: 5, 
                                              commercials: [@commercial1, @commercial2], 
                                              station_id: 2,  
                                              airtime: Time.new(2014,10,1, 12),
                                              current_position: 5,
                                              key: 'test_key',
                                               })
  end

  it "is created with an id, default duration 3:00 (180000 ms)" do
    expect(@commercial_block.id).to eq(5)
    expect(@commercial_block.duration).to eq(180000)
    expect(@commercial_block.commercials.map { |c| c.id }).to eq([@commercial1.id, @commercial2.id])
    expect(@commercial_block.station_id).to eq(2)
    expect(@commercial_block.airtime.to_s).to eq(Time.new(2014,10,1, 12).to_s)
    expect(@commercial_block.key).to eq('test_key')
    expect(@commercial_block.current_position).to eq(5)
  end

  it 'can store its current_position' do
    commercial_block = PL::CommercialBlock.new({ id: 5, station_id: 2 })
    commercial_block.current_position = 1
    expect(commercial_block.current_position).to eq(1)
  end

  it 'can create a hash of itself' do
    hash = @commercial_block.to_hash
    expect(hash[:id]).to eq(5)
    expect(hash[:duration]).to eq(180000)
    expect(hash[:commercials].map { |c| c.id }).to eq([@commercial1.id, @commercial2.id])
    expect(hash[:station_id]).to eq(2)
    expect(hash[:airtime].to_s).to eq(Time.new(2014,10,1, 12).to_s)
    expect(hash[:key]).to eq('test_key')
    expect(hash[:airtime_in_ms]).to eq(Time.new(2014,10,1, 12).to_f*1000)
    expect(hash[:current_position]).to eq(5)
  end
end
