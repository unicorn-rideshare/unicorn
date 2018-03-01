require 'rails_helper'

describe Notification do
  describe '#create' do
    it 'should enqueue a PushNotificationJob in resque' do
      allow(Resque).to receive(:enqueue).with(anything, anything, anything)
      expect(Resque).to receive(:enqueue).with(PushNotificationJob, anything, {})
      FactoryGirl.create(:notification)
    end
  end
end
