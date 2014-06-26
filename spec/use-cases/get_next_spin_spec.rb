require 'spec_helper'

describe 'GetNextSpin' do
	it 'calls bullshit if station is not found' do
		result = PL::GetNextSpin.run(9999)
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:station_not_found)
	end

  xit 'grabs the next spin' do
  end

end