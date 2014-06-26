require 'spec_helper'

describe 'a commercial_block' do
  it "is created with an id, default duration 3:00 (180000 ms)" do
    commercial_block = PL::CommercialBlock.new({ id: 5, commercials: [1,3,5], station_id: 2 })
    expect(commercial_block.id).to eq(5)
    expect(commercial_block.duration).to eq(180000)
    expect(commercial_block.commercials).to eq([1,3,5])
    expect(commercial_block.station_id).to eq(2)
  end

  it 'can store its cb_position' do
    commercial_block = PL::CommercialBlock.new({ id: 5, commercials: [1,3,5], station_id: 2 })
    commercial_block.cb_position = 1
    expect(commercial_block.cb_position).to eq(1)
  end
end
