require 'spec_helper'

describe 'DeleteCommentary' do
	it 'calls bullshit if commentary is not found' do
		result = PL::DeleteCommentary.run(55)
		expect(result.success?).to eq(false)
		expect(result.error).to eq(:commentary_not_found)
	end

	it 'deletes a commentary' do
		commentary = PL.db.create_commentary({ schedule_id: 1 })
		result = PL::DeleteCommentary.run(commentary.id)
		expect(result.success?).to eq(true)
		expect(result.commentary.schedule_id).to eq(1)
		expect(PL.db.get_commentary(commentary.id)).to be_nil
	end
end