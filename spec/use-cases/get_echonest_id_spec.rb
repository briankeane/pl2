require 'spec_helper'

describe 'GetEchonestId' do
  it 'returns failure if no echonest_id found' do
    result = PL::GetEchonestId.run({ title: 'asdf', artist: 'asfdasdf' })
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:no_echonest_id_found)
  end

  it 'gets the echonest_id for a song' do
    result = PL::GetEchonestId.run({ title: 'Stepladder', artist: 'Rachel Loy' })
    expect(result.success?).to eq(true)
    expect(result.artist).to eq('Rachel Loy')
    expect(result.title).to eq('Stepladder')
    expect(result.echonest_id).to eq('SOOWAAV13CF6D1B3FA')
  end
end
