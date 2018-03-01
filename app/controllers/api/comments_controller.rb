module Api
  class CommentsController < Api::ApplicationController
    load_resource :attachment
    load_resource :job
    load_resource :work_order
    load_resource :customer
    before_action :authorize_parent
    load_and_authorize_resource through: [:attachment, :job, :work_order, :customer]

    def index
      @comments = filter_by(@comments.greedy, indexes)
      respond_with(:api, @comments)
    end

    def show
      respond_with(:api, @comment)
    end

    def create
      @comment.user = current_user
      @comment.save && true
      respond_with(:api, @comment, template: 'api/comments/show', status: :created)
    end

    private

    def authorize_parent
      authorize! :read, (@attachment || @job || @work_order || @customer)
    end

    def indexes
      [:user_id, [:commentable_id, :commentable_type]]
    end

    def comment_params
      params.permit(:body, :latitude, :longitude)
    end
  end
end
