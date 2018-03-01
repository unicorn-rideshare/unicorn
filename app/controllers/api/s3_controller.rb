module Api
  class S3Controller < Api::ApplicationController

    def presign
      presigned_post = s3_bucket.presigned_post(presigned_post_options) rescue nil
      raise Unicorn::HttpErrors::BadRequest unless presigned_post
      render json: { fields: presigned_post.fields, url: presigned_post.url.to_s } if presigned_post
    end

    private

    def s3_bucket
      @s3_bucket ||= Aws::S3::Bucket.new(params[:bucket] || Settings.aws.default_s3_bucket)
    end

    def presigned_post_options
      @presigned_post_options ||= begin
        filename = params[:filename].presence
        extension = File.extname(filename).gsub(/\./, '') rescue nil
        key = "#{SecureRandom.uuid}#{extension ? ".#{extension}" : ''}"
        content_type = Mime::Type.lookup_by_extension(extension) rescue nil
        acl = (params[:acl] || :public_read).to_sym
        expires = DateTime.parse(params[:expires]) rescue (DateTime.now + 5.minutes)
        options = { acl: acl.to_s.gsub(/_/i, '-'), expires: expires, key: key }
        options[:content_type] = content_type.to_s if content_type
        options[:metadata] = JSON.parse(params[:metadata]) rescue JSON.parse(URI.decode(params[:metadata])) if params[:metadata]
        options
      end
    end
  end
end
