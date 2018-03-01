class FetchFromSourceUrlJob
  @queue = :high

  class << self
    def perform(attachment_id)
      attachment = Attachment.unscoped.find(attachment_id) rescue nil
      return unless attachment && attachment.source_url

      response = Typhoeus::Request.get(attachment.source_url)
      if response.code == 200
        bucket = Aws::S3::Bucket.new(Settings.aws.default_s3_bucket)
        if bucket.exists?
          attachment.mime_type = response.headers['content-type']
          attachment.url = "https://#{Settings.aws.default_s3_bucket}.s3.amazonaws.com/#{attachment.key}"

          metadata = {}
          metadata[:tags] = attachment.tags.join(',') if attachment.tags && attachment.tags.size > 0

          s3_object = attachment.s3_object
          s3_object.put(body: response.body, content_type: attachment.mime_type, metadata: metadata, acl: :public_read)

          attachment.publish!
        end
      end
    end
  end
end
