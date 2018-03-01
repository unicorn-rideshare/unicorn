require 'rails_helper'

describe JwtToken do
  it { should belong_to(:company) }
  it { should belong_to(:provider) }

  describe '#create' do
    context 'when the created JwtToken is less than 8KB' do
      let(:authenticable) { FactoryGirl.create(:provider) }

      subject { FactoryGirl.create(:jwt_token, provider: authenticable) }
    end

    # context 'when the created JwtToken exceeds 8KB' do
    #   let(:authenticable) { company = FactoryGirl.create(:company); company.update_attribute(:config, { bigtext: '1' * 8192 }); company }
    #
    #   subject { FactoryGirl.create(:jwt_token, company: authenticable) }
    #
    #   it 'should create a surrogate JwtToken' do
    #     expect(subject.reload.surrogate).to_not eq(nil)
    #   end
    #
    #   it 'should have a :grantor referencing the original authenticable' do
    #     expect(subject.reload.surrogate.grantor.authenticable).to eq(authenticable)
    #   end
    #
    #   it 'should encode the surrogate JwtToken in the original JwtToken representation' do
    #     expect(JWT.decode(subject.token, subject.secret)[0]['surrogate']).to_not eq(nil)
    #   end
    # end
  end

  describe '#authenticate' do
    let(:jwt_token) { FactoryGirl.create(:jwt_token, provider: FactoryGirl.create(:provider)) }
    let(:jwt) { jwt_token.token }

    subject { JwtToken.authenticate(jwt) }

    context 'when a JwtToken with valid signature is provided' do
      context 'when the JwtToken has no expiration' do
        xit 'should return the JwtToken instance' do
          expect(subject).to eq(jwt_token)
        end
      end

      context 'when the JwtToken :expires_at timestamp is set' do
        let(:expires_at) { DateTime.now + 5.minutes }
        let(:jwt_token) { FactoryGirl.create(:jwt_token, expires_at: expires_at, provider: FactoryGirl.create(:provider)) }

        context 'when the JwtToken has not expired' do
          xit 'should return the JwtToken instance' do
            expect(subject).to eq(jwt_token)
          end
        end

        context 'when the JwtToken has expired' do
          before { Timecop.travel(expires_at + 1) }

          xit 'should return nil' do
            expect(subject).to eq(nil)
          end
        end
      end
    end

    context 'when an invalid JwtToken is provided' do
      xit 'should return nil' do
        expect(JwtToken.authenticate('invalid-jwt')).to eq(nil)
      end
    end
  end
end
