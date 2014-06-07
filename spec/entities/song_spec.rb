require 'spec_helper'

describe 'Song' do
	it 'is created with id, artist, title, album, duration, :key' do
	song = PL::Song.new({     id: 1,
						  artist: 'Rachel Loy',
						   title: 'Stepladder',
						   album: 'Broken Machine',
						duration: 180000,
						     key: 'ThisIsAKey.mp3' })
	expect(song.id).to eq(1)
	expect(song.artist).to eq('Rachel Loy')
	expect(song.title).to eq('Stepladder')
	expect(song.album).to eq('Broken Machine')
	expect(song.duration).to eq(180000)
	expect(song.key).to eq('ThisIsAKey.mp3')
	end

end