require 'rails_helper'

describe WorkOrderProviderMailer, type: :mailer do
  let(:work_order)  { FactoryGirl.create(:work_order, :with_provider) }

  describe '.invitation' do
    let(:invitation)  { work_order.work_order_providers.first.invitations.create }
    let(:mail) { WorkOrderProviderMailer.deliver_invitation(invitation) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('You have a work order!')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.providers.first.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the user by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.providers.first.contact.name.split(/\s+/)[0]}!")
    end
  end
end
