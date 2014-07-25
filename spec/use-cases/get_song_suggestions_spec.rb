require 'spec_helper'

describe 'GetSongSuggestions' do
  it 'takes in artists and returns a list of available songs' do
    result = PL::GetSongSuggestions.run(['Bob Dylan', 'Rachel Loy', 'Billy Gillman'])
    expect(result.success?).to eq(true)
    expect(result[:song_suggestions].size).to eq(1)
  end
end