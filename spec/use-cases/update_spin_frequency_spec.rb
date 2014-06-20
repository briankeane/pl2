require 'spec_helper'

describe 'UpdateSpinFrequency' do
	it 'calls bullshit if the station is not found' do
		song = PL.db.create_song({ artist: 'Rachel Loy' })
		result = PL::UpdateSpinFrequency.run({ station_id: 999,
																							song_id: song.id,
																							spins_per_week: 90
																						})
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:station_not_found)
	end

	it 'calls bullshit if the song does not exist' do
		station = PL.db.create_station({ user_id: 1 })
		result = PL::UpdateSpinFrequency.run({ station_id: station.id,
																							song_id: 999,
																							spins_per_week: 90
																						})
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:song_not_found)
	end

	it 'updates a spin frequency' do
		song = PL.db.create_song({ artist: 'Rachel Loy' })
		station = PL.db.create_station({ user_id: 1 })
		PL.db.create_spin_frequency({ station_id: station.id,
																	song_id: song.id,
																	spins_per_week: 50
																})
		result = PL::UpdateSpinFrequency.run({ station_id: station.id,
																							song_id: song.id,
																							spins_per_week: 90
																						})
		expect(result.success?).to eq(true)
		expect(result.updated_station.id).to eq(station.id)
		expect(result.updated_station.spins_per_week[song.id]).to eq(90)
	end
end