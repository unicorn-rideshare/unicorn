require 'rails_helper'

describe WorkOrderService do
  describe '#calculate_availability' do
    let(:company)    { FactoryGirl.create(:company) }

    let(:customer)   { FactoryGirl.create(:customer,
                                          company: company,
                                          contact: FactoryGirl.create(:contact, contactable_type: 'Customer', time_zone_id: 'Eastern Time (US & Canada)')) }

    let(:work_order) { FactoryGirl.create(:work_order,
                                          company: company,
                                          customer: customer,
                                          estimated_duration: 240) }

    let(:options)    { { start_date: '2014-07-17',
                         end_date: '2014-07-18',
                         customer_id: work_order.customer_id } }

    let(:availability) { WorkOrderService.calculate_availability(options.with_indifferent_access) }

    let(:now) { Time.utc(2014, 7, 16) }
    before { Timecop.freeze(now) }

    context 'given params are invalid' do
      let(:availability) { WorkOrderService.calculate_availability({}.with_indifferent_access) }

      it 'should return nil' do
        expect(availability).to be_nil
      end
    end

    it 'should calculate and return the availability' do
      time = TimeZone.find('Eastern Time (US & Canada)').local(2014, 7, 17)
      expected_availability = 48.times.map { |step| (time + step * 30.minutes).iso8601 }
      expect(availability).to eq(expected_availability)
    end
  end
end
