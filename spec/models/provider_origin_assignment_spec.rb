require 'rails_helper'

describe ProviderOriginAssignment do


  it { should belong_to(:origin) }
  it { should validate_presence_of(:origin) }

  it { should belong_to(:provider) }
  it { should validate_presence_of(:provider) }

  it { should have_many(:routes) }

  describe '#valid?' do
    let(:company)                    { FactoryGirl.create(:company) }
    let(:origin)                     { FactoryGirl.create(:origin, company: company) }
    let(:provider)                   { FactoryGirl.create(:provider, :with_origin_assignment, company: company) }
    let(:provider_origin_assignment) { provider.origin_assignments.first }

    it 'should not allow the origin to change' do
      new_origin = FactoryGirl.create(:origin)
      provider_origin_assignment.update_attributes(origin: new_origin) && true
      expect(provider_origin_assignment.errors[:origin_id]).to include(I18n.t('errors.messages.readonly'))
    end

    it 'should not allow the provider to change' do
      new_provider = FactoryGirl.create(:provider)
      provider_origin_assignment.update_attributes(provider: new_provider) && true
      expect(provider_origin_assignment.errors[:provider_id]).to include(I18n.t('errors.messages.readonly'))
    end

    it 'should associate the provider with an origin assignment in a market that belongs to its company' do
      our_origin = FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: provider.company))
      provider_origin_assignment = ProviderOriginAssignment.new(provider: provider, origin: our_origin)
      provider_origin_assignment.valid?
      expect(provider_origin_assignment.errors[:origin_id]).to_not include(I18n.t('errors.messages.work_order_market_company_confirmation'))
    end

    it 'should not associate the provider with an origin assignment in a market that does not belong to its company' do
      provider_origin_assignment = ProviderOriginAssignment.new(provider: provider, origin: FactoryGirl.create(:origin))
      provider_origin_assignment.valid?
      expect(provider_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_market_provider_company_confirmation'))
    end

    context 'when the provider already has an existing origin assignment' do
      before { provider_origin_assignment }

      context 'when the existing provider origin assignment is indefinite' do # nil start_date and nil end_date
        it 'should not allow an additional origin assignment to be created for the provider' do
          new_provider_origin_assignment = ProviderOriginAssignment.new(provider: provider_origin_assignment.provider,
                                                                        origin: provider_origin_assignment.origin)
          new_provider_origin_assignment.valid?
          expect(new_provider_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_indefinite'))
        end
      end

      context 'when the existing provider origin assignment has a start date' do
        let(:start_date) { Date.parse('2014-06-01') }

        before do
          provider_origin_assignment.start_date = start_date
          provider_origin_assignment.save
        end

        it 'should not allow an additional origin assignment to be created for the provider' do
          new_provider_origin_assignment = ProviderOriginAssignment.new(provider: provider_origin_assignment.provider,
                                                                        origin: provider_origin_assignment.origin)
          new_provider_origin_assignment.valid?
          expect(new_provider_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_indefinite'))
        end

        context 'when the existing provider origin assignment has an end date' do
          let(:end_date)   { start_date + 5.days }

          before do
            provider_origin_assignment.end_date = end_date
            provider_origin_assignment.save
          end

          context 'when the existing provider origin assignment ends before the new one starts' do
            it 'should allow an additional origin assignment to be created for the provider' do
              new_provider_origin_assignment = ProviderOriginAssignment.new(provider: provider_origin_assignment.provider,
                                                                            origin: provider_origin_assignment.origin,
                                                                            start_date: end_date + 1.day,
                                                                            end_date: end_date + 1.day)
              expect(new_provider_origin_assignment.valid?).to eq(true)
            end
          end
        end
      end

      context 'when the effective date range is invalid' do
        let(:start_date)  { Date.parse('2014-06-01') }
        let(:end_date)    { Date.parse('2014-05-01') }

        before do
          provider_origin_assignment.start_date = start_date
          provider_origin_assignment.end_date = end_date
        end

        it 'should not allow the start date to be after the end date' do
          provider_origin_assignment.valid?
          expect(provider_origin_assignment.errors[:base]).to include(I18n.t('errors.messages.origin_assignment_effective_date_range'))
        end
      end
    end
  end

  describe 'state machine' do
    describe 'scheduled' do
      let(:provider_origin_assignment) { FactoryGirl.create(:provider_origin_assignment, start_date: Date.today, end_date: Date.today) }

      it 'should be scheduled upon creation' do
        expect(provider_origin_assignment.scheduled).not_to be_nil
      end
      
      describe '#cancel!' do
        it 'should set the :canceled_at timestamp on the provider origin assignment' do
          expect(provider_origin_assignment.canceled_at).to be_nil
          provider_origin_assignment.cancel!
          expect(provider_origin_assignment.canceled_at).not_to be_nil
        end
      end
      
      describe '#clock_in!' do
        it 'should set the :started_at timestamp on the work order' do
          expect(provider_origin_assignment.started_at).to be_nil
          provider_origin_assignment.clock_in!
          expect(provider_origin_assignment.started_at).not_to be_nil
        end
      end
    end

    describe '#clock_out!' do
      let(:provider_origin_assignment) { FactoryGirl.create(:provider_origin_assignment, :in_progress, start_date: Date.today, end_date: Date.today) }

      it 'should set the :ended_at timestamp on the provider origin assignment' do
        expect(provider_origin_assignment.ended_at).to be_nil
        provider_origin_assignment.clock_out!
        expect(provider_origin_assignment.ended_at).not_to be_nil
      end

      it 'should set the :duration on the provider origin assignment' do
        expect(provider_origin_assignment.duration).to be_nil
        provider_origin_assignment.clock_out!
        expect(provider_origin_assignment.duration).not_to be_nil
      end
    end
  end
end
