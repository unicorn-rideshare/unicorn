require 'rails_helper'

describe WorkOrderMailer, type: :mailer do
  let(:work_order) { FactoryGirl.create(:work_order, :with_provider) }

  describe '.deliver_customer_service_notification' do
    let(:mail) { WorkOrderMailer.deliver_customer_service_notification(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Attention Required')
    end

    it 'renders the receiver email' do
      expect(mail.to.last).to eq(work_order.company.contact.email)
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end
  end

  describe '.deliver_due_date_escalation' do
    let(:deliveries) { WorkOrderMailer.deliver_due_date_escalation(work_order) }

    it 'sends the email' do
      expect { deliveries }.to change(ActionMailer::Base.deliveries, :count).by(work_order.providers.count)
    end

    it 'renders the subject' do
      deliveries.each do |mail|
        expect(mail.subject).to eq('Attention: Timeline at Risk')
      end
    end

    it 'renders the receiver email' do
      deliveries.each do |mail|
        expect(mail.to).to eq([work_order.providers.first.contact.email])
      end
    end

    it 'renders the sender email' do
      deliveries.each do |mail|
        expect(mail.from).to eq([Settings.app.default_mailer_from_address])
      end
    end

    it 'addresses the provider by first name' do
      deliveries.each do |mail|
        expect(mail.body.encoded).to match("Hi #{work_order.providers.first.contact.first_name}!")
      end
    end
  end

  describe '.deliver_morning_of_reminder' do
    let(:mail) { WorkOrderMailer.deliver_morning_of_reminder(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Appointment Today')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.customer.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the customer by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.customer.contact.first_name}!")
    end
  end

  describe '.deliver_reminder' do
    let(:mail) { WorkOrderMailer.deliver_reminder(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Reminder About Your Upcoming Appointment')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.customer.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the customer by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.customer.contact.first_name}!")
    end
  end

  describe '.deliver_scheduled_confirmation' do
    let(:mail) { WorkOrderMailer.deliver_scheduled_confirmation(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Appointment Has Been Scheduled')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.customer.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the customer by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.customer.contact.first_name}!")
    end
  end

  describe '.deliver_upon_abandoned_follow_up' do
    let(:mail) { WorkOrderMailer.deliver_upon_abandoned_follow_up(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('We Missed You')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.customer.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the customer by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.customer.contact.first_name}!")
    end
  end

  describe '.deliver_upon_completion_follow_up' do
    let(:mail) { WorkOrderMailer.deliver_upon_completion_follow_up(work_order) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Thank You For Your Business')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([work_order.customer.contact.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the customer by first name' do
      expect(mail.body.encoded).to match("Hi #{work_order.customer.contact.first_name}!")
    end
  end
end
