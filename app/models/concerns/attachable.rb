module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments,
             as: :attachable,
             after_add: :attachment_added,
             after_remove: :attachment_removed,
             dependent: :destroy

    def attachment_published(attachment)
      # no-op by default
    end

    def profile_images
      profile_images = attachments.greedy.select { |attachment| attachment.tags && attachment.tags.include?('profile_image') }
      (profile_images + profile_images.map(&:representations)).flatten
    end

    def profile_image_url
      url = nil
      attachment = profile_images.select { |profile_image| profile_image.tags.include?('default') }.first || profile_images.last
      url = attachment.display_url || attachment.url if attachment
      url
    end

    private

    def attachment_added(attachment)
      # no-op by default
    end

    def attachment_removed(attachment)
      # no-op by default
    end
  end
end
