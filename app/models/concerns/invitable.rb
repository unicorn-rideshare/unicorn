module Invitable
  extend ActiveSupport::Concern

  included do
    has_many :invitations,
             as: :invitable,
             after_add: :invitation_received,
             dependent: :destroy

    private

    def invitation_received(invitation)
      # no-op by default
    end
  end
end
