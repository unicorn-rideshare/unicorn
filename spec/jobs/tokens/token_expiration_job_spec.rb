require 'rails_helper'

describe TokenExpirationJob do
  describe '.perform' do
    subject { TokenExpirationJob.perform(token.id) }

    context 'when the token has expired' do
      let(:token) { FactoryGirl.create(:token, :expired) }

      it 'destroys the token' do
        token_str = token.token
        subject
        expect(Token.unscoped.where(token: token_str).count).to eq(0)
      end
    end
  end
end
