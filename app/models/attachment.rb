class Attachment < ActiveRecord::Base
  include Commentable
  include Notifiable
  include StateMachine

  belongs_to :attachable, polymorphic: true
  validates :attachable_id, allow_nil: true, readonly: true, on: :update
  validates :attachable_type, allow_nil: true, readonly: true, on: :update

  validates :key, readonly: true, on: :update

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  validates :source_url, readonly: true, on: :update

  has_many :representations, class_name: Attachment.name, dependent: :destroy, foreign_key: :parent_attachment_id

  before_validation :initialize_key_from_source_url, on: :create, if: lambda { !self.key && self.source_url }

  after_create :fetch_from_source_url, if: lambda { self.source_url }

  after_create { self.reload.publish! if self.url && !self.is_audio? && !self.is_video? && !self.is_profile_image? }

  after_save :cleanup_tags, if: lambda { self.tags_changed? }

  after_destroy :delete_s3_object,
                :delete_s3_map_tile_objects

  default_scope { order('attachments.created_at ASC') }

  scope :greedy, ->() {
    includes(:representations)
  }

  scope :include_user, ->() {
    includes(:user)
  }

  aasm column: :status, whiny_transitions: false do
    state :pending, initial: true
    state :published
    state :error

    event :publish do
      transitions from: :pending, to: :published

      after do
        self.notifiable.attachment_published(self) if self.notifiable
      end
    end
  end

  def add_version(params)
    url = params.delete(:url)
    key = URI.parse(url).path.split(/\//).last rescue nil
    source_url = params.delete(:source_url)
    extension = File.extname(url.split(/\//).last)[1..-1] rescue nil
    mime_type = Mime::Type.lookup_by_extension(extension).to_s if extension

    representation = self.representations.create(user: self.user,
                                                 key: key,
                                                 latitude: self.latitude,
                                                 longitude: self.longitude,
                                                 metadata: params,
                                                 mime_type: mime_type,
                                                 public: self.public,
                                                 source_url: source_url,
                                                 tags: self.tags,
                                                 url: url)

    publish = self.status.downcase.to_sym == :pending && self.is_profile_image?
    publish ? (self.publish! && representation.publish!) : (self.save && representation.save)
  end

  def display_url
    return nil unless self.status.downcase.to_sym == :published
    return nil unless self.is_profile_image? || self.is_thumbnail_image?
    versions = self.metadata['versions']
    return versions.first['url'] if versions && versions.size > 0
    self.representations.first.url if self.representations.size == 1 && (self.representations.first.try(:is_profile_image?) || self.representations.first.try(:is_thumbnail_image?))
  end

  def is_audio?
    self.mime_type && self.mime_type.match(/^audio/i)
  end

  def is_image?
    self.mime_type && self.mime_type.match(/^image/i)
  end

  def is_pdf?
    self.mime_type && self.mime_type.match(/^application\/pdf$/i)
  end

  def is_profile_image?
    self.tags && self.tags.include?('profile_image')
  end

  def is_thumbnail_image?
    self.is_image? && self.tags && self.tags.include?('thumbnail')
  end

  def is_video?
    self.mime_type && self.mime_type.match(/^video/i)
  end

  def notifiable
    @notifiable ||= self.parent_attachment_id ? (self.parent_attachment.try(:notifiable) || self.attachable) : self.attachable rescue nil
  end

  def parent_attachment
    @parent_attachment ||= Attachment.find(self.parent_attachment_id) rescue nil
  end

  def s3_bucket
    @s3_bucket ||= begin
      uri = URI.parse(self.url) if self.url
      host_parts = uri.host.split(/\./) if uri
      path_parts = uri.path.split(/\//).reject { |segment| segment.length == 0 } if uri
      is_virtual_style_url = host_parts && host_parts[0].match(/^s3/i).nil?
      is_path_style_url = path_parts && path_parts.count == 2
      bucket_name = is_virtual_style_url ? host_parts[0] : (is_path_style_url ? path_parts[0] : Settings.aws.default_s3_bucket)
      bucket = Aws::S3::Bucket.new(bucket_name) rescue nil
      bucket if (bucket && bucket.exists? rescue false)
    end
  end

  def s3_object
    return nil unless self.key && self.s3_bucket
    @s3_object ||= begin
      self.s3_bucket.object(self.key)
    end
  end

  private

  def cleanup_tags
    return unless is_profile_image?
    new_default_profile_image = self.tags && self.tags.include?('profile_image') && self.tags.include?('default')
    self.notifiable.attachments.select { |attachment| attachment.tags && attachment.tags.include?('profile_image') }.each do |a|
      a.tags.delete('default') && a.save && true unless a == self || a == self.parent_attachment
      a.representations.each do |representation|
        representation.tags.delete('default') && representation.save && true unless representation == self
      end
    end if new_default_profile_image
  end

  def delete_s3_object
    return unless s3_object
    s3_object.delete rescue nil
  end

  def delete_s3_map_tile_objects
    tiling_inbox_s3_bucket = Aws::S3::Bucket.new(Settings.aws.map_tiling_inbox_s3_bucket) rescue nil
    return unless tiling_inbox_s3_bucket && tiling_inbox_s3_bucket.exists? && tiling_inbox_s3_bucket == self.s3_bucket
    tiling_inbox_s3_bucket.objects.select { |s3_object| s3_object.key.match(/^#{self.key}.*/i) }.map(&:delete) rescue nil
  end

  def fetch_from_source_url
    return unless self.source_url
    Resque.enqueue(FetchFromSourceUrlJob, self.id)
  end

  def initialize_key_from_source_url
    return unless !self.key && self.source_url
    extension = File.extname(URI.parse(self.source_url).path.split(/\//).last) rescue nil
    self.key = "#{SecureRandom.uuid}#{extension || ''}"
  end

  def notification_params(notification_type)
    tags = self.tags || []
    {
        attachment_id: self.id,
        attachable_type: self.attachable_type.try(:underscore),
        attachable_id: self.attachable_id,
        refresh_profile_image: self.is_profile_image? && tags.include?('default')
    }
  end

  def notification_recipients(notification_type)
    [self.user]
  end

  def send_notification?(notification_type)
    self.notifiable.send_attachment_notification?(notification_type, self) rescue false if self.notifiable
  end
end
