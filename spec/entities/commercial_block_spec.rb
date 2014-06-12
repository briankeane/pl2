require 'spec_helper'

describe 'a station' do
  it "is created with an id, default duration 3:00 (180000 ms)" do
    station = PL::CommercialBlock.new({ id: 5, commercials: [1,3,5] })
    expect(station.id).to eq(5)
    expect(station.duration).to eq(180000)
    expect(station.commercials).to eq([1,3,5])
  end
end
