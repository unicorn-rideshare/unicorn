module Api
  class ContactsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @contacts = filter_by(@contacts, indexes)
      respond_with(:api, @contacts)
    end

    def show
      respond_with(:api, @contact)
    end

    def update
      @contact.update(contact_params)
      respond_with(:api, @contact)
    end

    private

    def contact_params
      params.permit(*permitted_contact_params)
    end

    def indexes
      [[:contactable_id, :contactable_type], :time_zone_id]
    end
  end
end
