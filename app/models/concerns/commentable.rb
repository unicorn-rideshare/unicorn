module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments,
             as: :commentable,
             after_add: :comment_added,
             after_remove: :comment_removed,
             dependent: :destroy

    private

    def comment_added(comment)
      # no-op by default
    end

    def comment_removed(comment)
      # no-op by default
    end
  end
end
