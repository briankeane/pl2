require 'spec_helper'

describe 'GetCommentary' do
  it 'calls bullshit if commentary not found' do
    result = PL::GetCommentary.run(9999)
    expect(result.success?).to eq(false)
    expect(result.error).to eq(:commentary_not_found)
  end

  it 'gets a commentary' do
    commentary = PL.db.create_commentary({ schedule_id: 4,
                                            duration: 10,
                                            key: 'ThisIsAKey.mp3'
                                        })
    result = PL::GetCommentary.run(commentary.id)
    expect(result.success?).to eq(true)
    expect(result.commentary.schedule_id).to eq(4)
    expect(result.commentary.duration).to eq(10)
    expect(result.commentary.key).to eq('ThisIsAKey.mp3')
  end
end