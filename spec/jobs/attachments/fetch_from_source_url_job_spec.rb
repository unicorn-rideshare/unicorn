require 'rails_helper'

describe FetchFromSourceUrlJob do
  let(:attachment) { FactoryGirl.create(:attachment, url: nil, source_url: 'https://example.com/test.pdf', tags: %w(pdf blueprint)) }

  describe '.perform' do
    let(:response) { Typhoeus::Response.new(code: 200,
                                            body: 'PDF body!!!',
                                            headers: { 'content-type' => 'application/pdf' }) }

    before { expect(Typhoeus::Request).to receive(:get).with('https://example.com/test.pdf') { response } }

    subject { FetchFromSourceUrlJob.perform(attachment.id) }

    it 'should fetch the attachment from the :source_url' do
      subject
    end

    it 'should write the attachment to S3' do
      expect_any_instance_of(Aws::S3::Object).to receive(:put).with(body: 'PDF body!!!', acl: :public_read, content_type: 'application/pdf', metadata: { tags: 'pdf,blueprint' })
      subject
    end

    it 'should set the :url on the attachment' do
      subject
      expect(attachment.reload.url).to_not be_nil
    end

    it 'should set the :status on the attachment to published' do
      expect(attachment.status.to_sym).to eq(:pending)
      subject
      expect(attachment.reload.status.to_sym).to eq(:published)
    end
  end
end
