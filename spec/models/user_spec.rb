require 'rails_helper'

describe User do
  let(:user) { FactoryGirl.create(:user) }

  it_behaves_like 'attachable'

  it_behaves_like 'authenticable'

  it_behaves_like 'contactable' do
    let(:contactable) { FactoryGirl.create(:user, :with_contact) }
  end

  it_behaves_like 'invitable' do
    let(:invitable) { FactoryGirl.create(:user) }
  end

  it_behaves_like 'locatable' do
    let(:locatable) { FactoryGirl.create(:user) }
  end

  # it_behaves_like 'notifiable' do
  #   let(:notifiable) { FactoryGirl.create(:user) }
  # end

  it { should have_many(:companies) }
  it { should have_many(:customers) }
  it { should have_many(:devices) }
  it { should have_many(:dispatchers) }
  it { should have_many(:providers) }

  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email) }

  it { should validate_presence_of(:name) }

  it { should have_many(:messages_sent) }
  it { should have_many(:messages_received) }

  describe '#reset_password' do
    subject { user.reset_password }

    it 'should set the :reset_password_token' do
      subject
      expect(user.reset_password_token).to_not be_nil
    end

    it 'should set the :reset_password_sent_at' do
      subject
      expect(user.reset_password_sent_at).to_not be_nil
    end

    it 'should enqueue a ResetPasswordNotificationJob' do
      expect(Resque).to receive(:enqueue).with(SendResetPasswordNotificationJob, user.id)
      subject
    end
  end

  describe '#preferences' do
    context 'when the user preferences are updated' do
      context 'when the user preferences contain a :default_company_id' do
        context 'when the user is a provider for the :default_company_id company' do
          let(:provider) { FactoryGirl.create(:provider, user: user) }
          let(:valid_default_company) { provider.company }

          subject { user.preferences = { default_company_id: valid_default_company.id }; user.save }

          it 'should allow the :default_company_id to be persisted' do
            subject
            expect(user.reload.preferences[:default_company_id].try(:to_i)).to eq(valid_default_company.id)
          end
        end

        context 'when the user has no association to the company' do
          let(:invalid_default_company) { FactoryGirl.create(:company) }

          subject { user.preferences = { default_company_id: invalid_default_company.id }; user.save }

          it 'should not allow the :default_company_id to be persisted' do
            subject
            expect(user.reload.preferences[:default_company_id]).to eq(nil)
          end
        end
      end
    end
  end

  describe '#profile_image_url' do
    context 'when the user has an attachment with a :profile_image tag' do
      let(:attachment) do
        FactoryGirl.create(:attachment,
                           attachable: user,
                           url: 'http://attachments.example.com/photo.jpg',
                           tags: %w(profile_image))
      end

      before  { attachment }
      subject { user }

      it 'should return the first url in the list since no :default tag is set' do
        expect(subject.profile_image_url).to eq('http://attachments.example.com/photo.jpg')
      end

      context 'when the profile image attachment has a :default tag' do
        before { attachment.update_attributes(tags: %w(default profile_image)) }

        it 'should return the attachment url' do
          expect(subject.profile_image_url).to eq('http://attachments.example.com/photo.jpg')
        end
      end
    end
  end

  describe '#default_company_id' do
    subject { user.default_company_id }

    context 'when the user has a :default_company_id preference set' do
      let(:user)     { provider.user }
      let(:provider) { FactoryGirl.create(:provider) }
      before { user.preferences = { default_company_id: provider.company_id }; user.save }

      it 'should return the :default_company_id preference' do
        expect(user.reload.default_company_id).to eq(provider.company_id)
      end
    end

    context 'when user is the admin of many companies' do
      let(:company1) { FactoryGirl.build :company, user: user }
      let(:company2) { FactoryGirl.build :company, user: user }

      before { company1 && company2 }

      it 'returns the id of the first company' do
        expect(subject).to eq(company1.id)
      end
    end

    context 'when user is not the admin of a company or a dispatcher or provider' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the user is a company admin' do
      let(:company1) { FactoryGirl.create(:company, user: user) }

      before do
        company1
        FactoryGirl.create(:dispatcher, user: user)
      end

      it 'returns the id of the company for which the user is an admin' do
        expect(subject).to eq(company1.id)
      end
    end

    context 'when the user is a dispatcher' do
      let(:dispatcher) { FactoryGirl.create(:dispatcher, user: user) }

      before { dispatcher }

      it 'returns the id of the company for which the user is a dispatcher' do
        expect(subject).to eq(dispatcher.company.id)
      end
    end

    context 'when the user is a provider' do
      let(:provider) { FactoryGirl.create(:provider, user: user) }
      before { provider }

      it 'returns the id of the company for which the user is a provider' do
        expect(subject).to eq(provider.company.id)
      end
    end
  end

  context 'when the user is a company admin' do
    before { FactoryGirl.create(:company, user: user) }

    describe '#is_company_admin?' do
      it 'should return true' do
        expect(user.is_company_admin?).to eq(true)
      end
    end

    describe '#is_dispatcher?' do
      it 'should return false' do
        expect(user.is_dispatcher?).to eq(false)
      end
    end

    describe '#is_provider?' do
      it 'should return false' do
        expect(user.is_provider?).to eq(false)
      end
    end
  end

  context 'when the user is a dispatcher' do
    before { FactoryGirl.create(:dispatcher, user: user) }

    describe '#is_company_admin?' do
      it 'should return false' do
        expect(user.is_company_admin?).to eq(false)
      end
    end

    describe '#is_dispatcher?' do
      it 'should return true' do
        expect(user.is_dispatcher?).to eq(true)
      end
    end

    describe '#is_provider?' do
      it 'should return false' do
        expect(user.is_provider?).to eq(false)
      end
    end
  end

  context 'when the user is a provider' do
    before { FactoryGirl.create(:provider, user: user) }

    describe '#is_company_admin?' do
      it 'should return false' do
        expect(user.is_company_admin?).to eq(false)
      end
    end

    describe '#is_dispatcher?' do
      it 'should return false' do
        expect(user.is_dispatcher?).to eq(false)
      end
    end

    describe '#is_provider?' do
      it 'should return true' do
        expect(user.is_provider?).to eq(true)
      end
    end
  end
end
