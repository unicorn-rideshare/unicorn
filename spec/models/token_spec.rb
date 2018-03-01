require 'rails_helper'

describe Token do
  it { should belong_to(:authenticable) }
  it { should validate_presence_of(:authenticable) }
  it { should validate_presence_of(:authenticable_id) }
  it { should validate_presence_of(:authenticable_type) }

  describe '#create' do
    context 'when :expires_at is not nil' do
      let(:expires_at) { DateTime.now + 10.minutes }
      let(:token) { FactoryGirl.create(:token, expires_at: expires_at) }

      subject { token }

      it 'should not attempt to remove any previous TokenExpirationJob for the token' do
        expect(Resque).not_to receive(:remove_delayed).with(TokenExpirationJob, token.id)
        subject
      end

      it 'should enqueue an TokenExpirationJob for the token' do
        allow(Resque).to receive(:remove_delayed).with(TokenExpirationJob, anything)
        expect(Resque).to receive(:enqueue_at).with(expires_at, TokenExpirationJob, anything)
        subject
      end
    end
  end

  describe '#destroy' do
    let(:token) { FactoryGirl.create(:token) }

    subject { token.destroy }

    context 'when the token never expires' do
      it 'should not attempt to remove the TokenExpirationJob for the token' do
        expect(Resque).not_to receive(:remove_delayed).with(TokenExpirationJob, token.id)
        subject
      end
    end

    context 'when the token has an :expires_at timestamp' do
      let(:token)  { FactoryGirl.create(:token, :expired) }

      it 'should remove the TokenExpirationJob for the token' do
        expect(Resque).to receive(:remove_delayed).with(TokenExpirationJob, token.id)
        subject
      end
    end
  end

  describe '#reset_token' do
    it 'should be called when a token is created' do
      user = FactoryGirl.create(:user)
      token = Token.new(token: 'some-token', token_hash: 'hashed-token', authenticable: user)
      expect(token).to receive(:reset_token)
      token.save!
    end
  end

  describe '#authenticate' do
    let(:token) { FactoryGirl.create(:token) }

    it 'should return false if the provided uuid does not match' do
      expect(token.authenticate('invalid')).to eq(false)
    end
  end

  describe '#valid?' do
    let(:token) { FactoryGirl.create(:token) }

    it 'should not allow the :authenticable_id to change' do
      new_user = FactoryGirl.create(:user)
      token.update_attributes(authenticable: new_user) && true
      expect(token.errors[:authenticable_id]).to include(I18n.t('errors.messages.readonly'))
    end

    it 'should not allow the :authenticable_type to change' do
      token.update_attributes(authenticable_type: 'Company') && true
      expect(token.errors[:authenticable_type]).to include(I18n.t('errors.messages.readonly'))
    end
  end
end
