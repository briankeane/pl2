require 'spec_helper'

describe 'a spin' do
	it 'is created with an id, current_position, audio_block_type, audio_block_id' do
		spin = PL::Spin.new({ id: 1, current_position: 2, audio_block_type: 'song', audio_block_id: 4,
													created_at: Time.new(1970),
													updated_at: Time.new(1970, 1, 2) })
		expect(spin.id).to eq(1)
		expect(spin.current_position).to eq(2)
		expect(spin.audio_block_type).to eq('song')
		expect(spin.audio_block_id).to eq(4)
		expect(spin.created_at).to eq(Time.new(1970))
		expect(spin.updated_at).to eq(Time.new(1970, 1, 2))
	end
end