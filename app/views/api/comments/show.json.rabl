object @comment => nil

attributes :id,
           :body,
           :commentable_id,
           :latitude,
           :longitude,
           :previous_comment_id

node(:commentable_type) do |comment|
  comment.commentable_type.try(:underscore)
end

node(:attachments) do |comment|
  partial 'attachments/index', object: comment.attachments
end

node(:created_at) do |comment|
  comment.created_at.iso8601
end

node(:user) do |comment|
  partial 'users/show', object: comment.user
end
