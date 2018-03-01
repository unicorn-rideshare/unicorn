module Api
  class AttachmentsController < Api::ApplicationController
    load_resource :user
    load_resource :category
    load_resource :comment
    load_resource :expense
    load_resource :job
    load_resource :work_order
    before_action :authorize_parent
    load_and_authorize_resource through: [:user, :category, :comment, :expense, :job, :work_order]

    around_action :parse_metadata, only: [:create, :update], unless: lambda { params[:metadata].nil? }
    before_action :parse_tags, only: [:create, :update], unless: lambda { params[:tags].nil? }

    def index
      @include_user = params[:include_user].to_s.match(/^true$/i)
      @attachments = filter_by(@attachments.greedy.include_user, indexes)
      respond_with(:api, @attachments)
    end

    def create
      create_params = attachment_params.merge(user: current_user, tags: @attachment.tags)
      @attachment = attachable.attachments.create(create_params)
      respond_with(:api, @attachment, template: 'api/attachments/show', status: :created)
    end

    def update
      @attachment.update(attachment_params)
      respond_with(:api, @attachment)
    end

    def destroy
      @attachment.destroy
      respond_with(:api, @attachment)
    end

    private

    def attachable
      @user || @category || @comment || @expense || @job || @work_order
    end

    def authorize_parent
      authorize! :read, attachable
      authorize! :read, (@job || @work_order) if attachable_type.constantize == Expense
    end

    def attachable_type
      return User.name if @user
      return Category.name if @category
      return Comment.name if @comment
      return Expense.name if @expense
      return Floorplan.name if @floorplan
      return Job.name if @job
      return ResidentialFloorplan.name if @residential_floorplan
      WorkOrder.name
    end

    def attachable_id
      return @user.id if @user
      return @category.id if @category
      return @comment.id if @comment
      return @expense.id if @expense
      return @floorplan.id if @floorplan
      return @job.id if @job
      return @residential_floorplan.id if @residential_floorplan
      @work_order.id
    end

    def indexes
      [:user_id, [:attachable_id, :attachable_type]]
    end

    def attachment_params
      params.permit(:description, :key, :metadata, :mime_type, :latitude, :longitude, :public, :source_url, :tags, :url)
    end

    def parse_metadata
      metadata = params.delete(:metadata)
      yield
      @attachment.update_attribute(:metadata, metadata) if metadata
    end

    def parse_tags
      tags = params.delete(:tags)
      tags = tags.split(/,/).map(&:strip) if tags && tags.is_a?(String)
      @attachment.tags = tags if tags
    end
  end
end
