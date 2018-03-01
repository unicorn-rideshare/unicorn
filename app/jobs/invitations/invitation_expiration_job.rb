class InvitationExpirationJob
  @queue = :high

  class << self
    def perform(invitation_id)
      invitation = Invitation.unscoped.find(invitation_id) rescue nil
      invitation.destroy if invitation && invitation.expired?
    end
  end
end
