require 'spec_helper'

describe 'a spin' do
	it 'is created with an id, current_position, audio_block_type, audio_block_id' do
		spin = PL::Spin.new({ id: 1, current_position: 2, audio_block_type: 'song', audio_block_id: 4 })
		expect(spin.id).to eq(1)
		expect(spin.current_position).to eq(2)
		expect(spin.audio_block_type).to eq('song')
		expect(spin.audio_block_id).to eq(4)
	end
end