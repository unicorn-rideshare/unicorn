require 'rails_helper'

describe RouteStartedStatusCheckupJob do
  let(:route) { FactoryGirl.create(:route) }

  describe '.perform' do
    context 'when the route status is :scheduled' do
      before do
        route.scheduled_start_at = DateTime.now + 5.days
        route.schedule!
      end

      it 'should mark the route as canceled' do
        RouteStartedStatusCheckupJob.perform(route.id)
        expect(route.reload.status).to eq('canceled')
      end
    end
  end
end
