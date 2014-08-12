require 'spec_helper'

describe 'GetSongMatchPossibilities' do
  it 'gets song match possibilities' do
    result = PL::GetSongMatchPossibilities.run({artist: 'rachel loy',
                                        title: 'stepladder' })
    expect(result.success?).to eq(true)
    expect(result.songlist.size).to eq(10)
    expect(result.songlist[0][:artist]).to eq('Rachel Loy')
  end
end