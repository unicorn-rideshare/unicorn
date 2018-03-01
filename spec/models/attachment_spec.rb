require 'rails_helper'

describe Attachment do
  let(:attachment) { FactoryGirl.create(:attachment) }

  it_behaves_like 'commentable'
  it_behaves_like 'notifiable'


  it { should belong_to(:attachable) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:user) }

  it { should have_many(:representations) }

  describe '#create' do
    it 'should set the created at time' do
      expect(attachment.created_at).to_not be_nil
    end

    context 'when the attachment is not created with a url' do
      let(:attachment) { FactoryGirl.create(:attachment, url: nil) }

      it 'should set the :status of the attachment to pending' do
        expect(attachment.status).to eq('pending')
      end

      context 'when the :source_url is set' do
        let(:attachment) { FactoryGirl.create(:attachment, url: nil, source_url: 'https://example.com/test.pdf') }

        it 'should enqueue a FetchFromSourceUrlJob' do
          expect(Resque).to receive(:enqueue).with(FetchFromSourceUrlJob, anything).once
          attachment
        end

        context 'when no key is set' do
          let(:attachment) { FactoryGirl.create(:attachment, url: nil, key: nil, source_url: 'https://example.com/test.pdf') }

          it 'should generate the attachment key prior to creating the attachment' do
            expect(attachment.key).to match(/(.*)\.pdf$/i)
          end
        end
      end
    end

    context 'when the attachment is created with a url' do
      context 'when the attachment is audio' do
        let(:attachment) { FactoryGirl.create(:attachment, mime_type: 'audio/mp4', url: 'https://example.com/test.mp4') }

        it 'should set the :status of the attachment to pending' do
          expect(attachment.reload.status).to eq('pending')
        end
      end

      context 'when the attachment is video' do
        let(:attachment) { FactoryGirl.create(:attachment, mime_type: 'video/m4v', url: 'https://example.com/test.m4v') }

        it 'should set the :status of the attachment to pending' do
          expect(attachment.reload.status).to eq('pending')
        end
      end

      context 'when the attachment is an image' do
        let(:attachment) { FactoryGirl.create(:attachment, mime_type: 'image/png', url: 'https://example.com/test.png') }

        context 'when the tags do not indicate that the attachment is a user profile image' do
          it 'should set the :status of the attachment to published' do
            expect(attachment.reload.status).to eq('published')
          end
        end

        context 'when the tags indicate that the attachment is a user profile image' do
          let(:attachment) { FactoryGirl.create(:attachment, mime_type: 'image/jpg', tags: %w(profile_image default), url: 'https://example.com/test.jpg') }

          it 'should set the :status of the attachment to pending' do
            expect(attachment.reload.status).to eq('pending')
          end
        end
      end
    end
  end

  describe '#destroy' do
    let(:attachment) { FactoryGirl.create(:attachment, key: 'attachment-key') }

    before { allow_any_instance_of(Aws::S3::Object).to receive(:delete) }

    subject { attachment.destroy }

    it 'should attempt to delete the associated s3 object' do
      expect_any_instance_of(Aws::S3::Object).to receive(:delete).once
      subject
    end

    context 'when there are additional representations' do
      before { FactoryGirl.create_list(:attachment, 2, parent_attachment_id: attachment.id) }

      it 'should destroy the representations' do
        expect(Attachment.where(parent_attachment_id: attachment.id).count).to eq(2)
        subject
        expect(Attachment.where(parent_attachment_id: attachment.id).count).to eq(0)
      end
    end
  end

  describe '#valid?' do
    it 'should not allow the key to change' do
      attachment.key = SecureRandom.uuid
      attachment.valid?
      expect(attachment.errors[:key]).to include("can't be changed")
    end

    it 'should not allow the user to change' do
      new_user = FactoryGirl.create(:user)
      attachment.user = new_user
      attachment.valid?
      expect(attachment.errors[:user_id]).to include("can't be changed")
    end

    it 'should not allow the attachable to change' do
      new_attachable = FactoryGirl.create(:user)
      attachment.attachable = new_attachable
      attachment.valid?
      expect(attachment.errors[:attachable_id]).to include("can't be changed")
    end

    it 'should not allow the source_url to change' do
      attachment.source_url = 'http://other_url.com'
      attachment.valid?
      expect(attachment.errors[:source_url]).to include("can't be changed")
    end
  end

  describe '#add_version' do
    context 'when the attachment is a user profile image' do
      let(:attachment) { FactoryGirl.create(:attachment, mime_type: 'image/png', tags: %w(profile_image), url: 'https://example.com/test.png') }

      subject { attachment.add_version(url: 'https://example.com/test-cropped.png', width: 300, height: 300) }

      it 'should create a representation for the attachment version' do
        expect(Attachment.where(parent_attachment_id: attachment.id).count).to eq(0)
        subject
        expect(Attachment.where(parent_attachment_id: attachment.id).count).to eq(1)
      end

      it 'should resolve the mime type of the added version' do
        subject
        expect(attachment.reload.representations.first.mime_type).to eq('image/png')
      end

      it 'should set the :status of the attachment to published' do
        expect(attachment.reload.status).to eq('pending')
        subject
        expect(attachment.reload.status).to eq('published')
      end
    end
  end
end
