require 'rails_helper'

describe JobProduct do
  let(:job) { FactoryGirl.create(:job, :with_materials) }
  let(:job_product) { job.materials.first }



  it { should belong_to(:job) }
  it { should validate_presence_of(:job) }

  it { should belong_to(:product) }
  it { should validate_presence_of(:product) }

  describe '#valid?' do
    it 'should not allow the company to change' do
      new_product = FactoryGirl.create(:product)
      job_product.update_attributes(product: new_product) && true
      expect(job_product.errors[:product_id]).to include("can't be changed")
    end

    it 'should not associate another companies product' do
      our_job = FactoryGirl.create(:job)
      their_product = FactoryGirl.create(:product)
      job_product = JobProduct.new(job: our_job, product: their_product)
      job_product.valid?
      expect(job_product.errors[:product_id]).to include(I18n.t('errors.messages.product_company_must_match_job_company'))
    end

    context 'the job and product are not a unique pair' do
      let(:job) { FactoryGirl.create(:job) }
      let(:product) { FactoryGirl.create(:product, company: job.company) }

      before { job.job_products.create(product: product) }

      it 'should not validate' do
        job_product = JobProduct.new(job: job, product: product)
        job_product.valid?
        expect(job_product.errors[:base]).to include(I18n.t('errors.messages.must_be_unique'))
      end
    end

    context 'the product was not specified' do
      it 'should not validate the product company' do
        our_job = FactoryGirl.create(:job)
        job_product = JobProduct.new(job: our_job, product: nil)
        job_product.valid?
        expect(job_product.errors[:provider_id]).to_not include(I18n.t('errors.messages.product_company_must_match_job_company'))
      end
    end

    context 'the job was not specified' do
      it 'should not validate the product company' do
        their_product = FactoryGirl.create(:product)
        job_product = JobProduct.new(job: nil, product: their_product)
        job_product.valid?
        expect(job_product.errors[:provider_id]).to_not include(I18n.t('errors.messages.product_company_must_match_job_company'))
      end
    end
  end

  describe '#create' do
    let(:product) { FactoryGirl.create(:product, company: job.company, data: { price: 19.99 }) }

    context 'when the :price on the job_product is not set' do
      context 'when the product data includes a :price' do

        subject { job.job_products.create(product: product) }

        it 'should cascade the product price to the job product instance' do
          expect(subject.price).to eq(19.99)
        end
      end
    end

    context 'when the :price on the job_product is set' do
      context 'when the product data includes a :price' do
        let(:product) { FactoryGirl.create(:product, company: job.company, data: { price: 19.99 }) }

        subject { job.job_products.create(product: product, price: 14.99) }

        it 'should not cascade the product price to the job product instance and use the job product price as given' do
          expect(subject.price).to eq(14.99)
        end
      end
    end
  end
end
