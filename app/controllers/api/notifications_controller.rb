module Api
  class NotificationsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @notifications = filter_by(@notifications, indexes)
      respond_with(:api, @notifications)
    end

    private

    def indexes
      [:recipient_id]
    end
  end
end
