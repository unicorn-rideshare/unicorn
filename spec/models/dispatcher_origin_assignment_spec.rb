require 'rails_helper'

describe DispatcherOriginAssignment do


  it { should belong_to(:origin) }
  it { should validate_presence_of(:origin) }

  it { should belong_to(:dispatcher) }
  it { should validate_presence_of(:dispatcher) }

  it { should have_many(:routes) }

  describe '#valid?' do
    let(:company)                       { FactoryGirl.create(:company) }
    let(:origin)                        { FactoryGirl.create(:origin, company: company) }
    let(:dispatcher)                    { FactoryGirl.create(:dispatcher, :with_origin_assignment, company: company) }
    let(:dispatcher_origin_assignment)  { dispatcher.origin_assignments.first }

    it 'should not allow the origin to change' do
      new_origin = FactoryGirl.create(:origin)
      dispatcher_origin_assignment.update_attributes(origin: new_origin) && true
      expect(dispatcher_origin_assignment.errors[:origin_id]).to include(I18n.t('errors.messages.readonly'))
    end

    it 'should not allow the dispatcher to change' do
      new_dispatcher = FactoryGirl.create(:dispatcher)
      dispatcher_origin_assignment.update_attributes(dispatcher: new_dispatcher) && true
      expect(dispatcher_origin_assignment.errors[:dispatcher_id]).to include(I18n.t('errors.messages.readonly'))
    end

    it 'should associate the dispatcher with an origin assignment in a market that belongs to its company' do
      our_origin = FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: dispatcher.company))
      dispatcher_origin_assignment = DispatcherOriginAssignment.new(dispatcher: dispatcher, origin: our_origin)
      dispatcher_origin_assignment.valid?
      expect(dispatcher_origin_assignment.errors[:origin_id]).to_not include(I18n.t('errors.messages.work_order_market_company_confirmation'))
    end

    it 'should not associate the dispatcher with an origin assignment in a market that does not belong to its company' do
      dispatcher_origin_assignment = DispatcherOriginAssignment.new(dispatcher: dispatcher, origin: FactoryGirl.create(:origin))
      dispatcher_origin_assignment.valid?
      expect(dispatcher_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_market_dispatcher_company_confirmation'))
    end

    context 'when the dispatcher already has an existing origin assignment' do
      before { dispatcher_origin_assignment }

      context 'when the existing dispatcher origin assignment is indefinite' do # nil start_date and nil end_date
        it 'should not allow an additional origin assignment to be created for the dispatcher' do
          new_dispatcher_origin_assignment = DispatcherOriginAssignment.new(dispatcher: dispatcher_origin_assignment.dispatcher,
                                                                            origin: dispatcher_origin_assignment.origin)
          new_dispatcher_origin_assignment.valid?
          expect(new_dispatcher_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_indefinite'))
        end
      end

      context 'when the existing dispatcher origin assignment has a start date' do
        let(:start_date) { Date.parse('2014-06-01') }

        before do
          dispatcher_origin_assignment.start_date = start_date
          dispatcher_origin_assignment.save
        end

        it 'should not allow an additional origin assignment to be created for the dispatcher' do
          new_dispatcher_origin_assignment = DispatcherOriginAssignment.new(dispatcher: dispatcher_origin_assignment.dispatcher,
                                                                            origin: dispatcher_origin_assignment.origin)
          new_dispatcher_origin_assignment.valid?
          expect(new_dispatcher_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_indefinite'))
        end

        context 'when the existing dispatcher origin assignment has an end date' do
          let(:end_date)   { start_date + 5.days }

          before do
            dispatcher_origin_assignment.end_date = end_date
            dispatcher_origin_assignment.save
          end

          context 'when the existing dispatcher origin assignment ends before the new one starts' do
            it 'should allow an additional origin assignment to be created for the dispatcher' do
              new_dispatcher_origin_assignment = DispatcherOriginAssignment.new(dispatcher: dispatcher_origin_assignment.dispatcher,
                                                                                origin: dispatcher_origin_assignment.origin,
                                                                                start_date: end_date + 1.day,
                                                                                end_date: end_date + 1.day)
              expect(new_dispatcher_origin_assignment.valid?).to eq(true)
            end
          end
        end
      end

      context 'when the effective date range is invalid' do
        let(:start_date)  { Date.parse('2014-06-01') }
        let(:end_date)    { Date.parse('2014-05-01') }

        before do
          dispatcher_origin_assignment.start_date = start_date
          dispatcher_origin_assignment.end_date = end_date
        end

        it 'should now allow the start date to be after the end date' do
          dispatcher_origin_assignment.valid?
          expect(dispatcher_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_effective_date_range'))
        end
      end
    end
  end
end
