require 'spec_helper'

describe 'User' do
	it 'is created with id, twitter, twitter_uid, email, birth_year, gender' do
		user = PL::User.new({ twitter: 'BrianKeaneTunes',
				   twitter_uid: 740,
						 email: 'lonesomewhistle@gmail.com',
					birth_year: 1977,
					    gender: 'male',
					        id: 1 })
		expect(user.twitter).to eq('BrianKeaneTunes')
		expect(user.email).to eq('lonesomewhistle@gmail.com')
		expect(user.birth_year).to eq(1977)
		expect(user.gender).to eq('male')
		expect(user.id).to eq(1)
	end
end
