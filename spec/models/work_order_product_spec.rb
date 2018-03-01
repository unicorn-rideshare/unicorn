require 'rails_helper'

describe WorkOrderProduct do
  let(:work_order) { FactoryGirl.create(:work_order, :with_materials) }
  let(:work_order_product) { work_order.materials.first }



  it { should belong_to(:work_order) }
  it { should validate_presence_of(:work_order) }

  it { should belong_to(:job_product) }
  it { should validate_presence_of(:job_product) }

  describe '#valid?' do
    it 'should not allow the job product to change' do
      new_job_product = FactoryGirl.create(:job, :with_materials).materials.first
      work_order_product.update_attributes(job_product: new_job_product) && true
      expect(work_order_product.errors[:job_product_id]).to include("can't be changed")
    end

    it 'should not associate a job product from another job' do
      our_work_order = FactoryGirl.create(:work_order)
      their_job_product = FactoryGirl.create(:job, :with_materials).materials.first
      work_order_product = WorkOrderProduct.new(work_order: our_work_order, job_product: their_job_product)
      work_order_product.valid?
      expect(work_order_product.errors[:job_product_id]).to include(I18n.t('errors.messages.job_products_job_must_match'))
    end

    context 'the work order and job product are not a unique pair' do
      let(:job) { FactoryGirl.create(:job, :with_materials) }
      let(:work_order) { FactoryGirl.create(:work_order, company: job.company, job: job) }
      let(:job_product) { job.materials.first }

      before { work_order.materials.create(job_product: job_product) }

      it 'should not validate' do
        work_order_product = WorkOrderProduct.new(work_order: work_order, job_product: job_product)
        work_order_product.valid?
        expect(work_order_product.errors[:base]).to include(I18n.t('errors.messages.must_be_unique'))
      end
    end

    context 'the job product was not specified' do
      it 'should not validate the job product' do
        our_work_order = FactoryGirl.create(:work_order)
        work_order_product = WorkOrderProduct.new(work_order: our_work_order, job_product: nil)
        work_order_product.valid?
        expect(work_order_product.errors[:job_product_id]).to_not include(I18n.t('errors.messages.job_products_job_must_match'))
      end
    end

    context 'the work order was not specified' do
      it 'should not validate the work order' do
        their_job_product = FactoryGirl.create(:job, :with_materials).materials.first
        work_order_product = WorkOrderProduct.new(work_order: nil, job_product: their_job_product)
        work_order_product.valid?
        expect(work_order_product.errors[:work_order_product_id]).to_not include(I18n.t('errors.messages.job_products_job_must_match'))
      end
    end
  end

  describe '#create' do
    let(:job_product) { FactoryGirl.create(:job, :with_materials).materials.first }

    context 'when the :price on the work_order_product is not set' do
      context 'when the product data includes a :price' do
        context 'when the job product does not include a :price' do
          before  { job_product.product.update_attribute(:data, { price: 19.99 }) }

          subject { work_order.work_order_products.create(job_product: job_product) }

          it 'should cascade the product price to the work order product instance' do
            expect(subject.price).to eq(19.99)
          end
        end

        context 'when the job product data does include a :price' do
          before { job_product.update_attribute(:price, 299.45) }

          subject { work_order.work_order_products.create(job_product: job_product) }

          it 'should initialize the product price to 299.45 by cascading the job product price' do
            expect(subject.price).to eq(299.45)
          end
        end
      end

      context 'when the product data does not include a :price' do
        context 'when the job product does not include a :price' do
          subject { work_order.work_order_products.create(job_product: job_product) }

          it 'should initialize the product price to 0.0 work order product instance' do
            expect(subject.price).to eq(0.00)
          end
        end

        context 'when the job product data does include a :price' do
          before { job_product.update_attribute(:price, 288.45) }

          subject { work_order.work_order_products.create(job_product: job_product) }

          it 'should initialize the product price to 288.45 by cascading the job product price' do
            expect(subject.price).to eq(288.45)
          end
        end
      end
    end
    
    context 'when the :price on the work_order_product is set' do
      context 'when the product data includes a :price' do
        subject { work_order.work_order_products.create(job_product: job_product, price: 5.99) }

        it 'should cascade the product price to the work order product instance' do
          expect(subject.price).to eq(5.99)
        end
      end
    end
  end
end
