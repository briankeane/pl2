require 'spec_helper'

describe 'TimezoneFinder' do
  it 'returns a correct timezone' do
    tzf = PL::TimezoneFinder.new
    expect(tzf.find_by_zip('78704')).to eq('Central Time (US & Canada)')
    expect(tzf.find_by_zip('90027')).to eq('Pacific Time (US & Canada)')
    expect(tzf.find_by_zip('80012')).to eq('Mountain Time (US & Canada)')
    expect(tzf.find_by_zip('02215')).to eq('Eastern Time (US & Canada)')
  end
end