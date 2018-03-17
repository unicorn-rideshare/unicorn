module Api
  class MessagesController < ApplicationController
    load_and_authorize_resource

    def index
      @messages = filter_by(@messages, indexes).to_a.reverse
      respond_with(:api, @messages)
    end

    def create
      @message.sender_id = current_user.id
      @message.save && true
      respond_with(:api, @message, template: 'api/messages/show', status: :created)
    end

    def conversations
      @messages = Message.user_conversations(current_user)
      respond_with(:api, @messages, template: 'api/messages/index', status: :ok)
    end

    private

    def indexes
      [:sender_id, :recipient_id]
    end

    def message_params
      params.permit(
        :recipient_id, :body, :media_url
      )
    end
  end
end
