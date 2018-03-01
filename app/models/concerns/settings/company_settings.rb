module CompanySettings
  extend ActiveSupport::Concern

  included do
    def config
      super.with_indifferent_access
    end

    def apn_certificate
      config[:apn_certificate]
    end

    def facebook_app_id
      config[:facebook_app_id]
    end
  end
end
