class GeocodeContactJob
  @queue = :high

  class << self
    def perform(contact_id)
      contact = Contact.unscoped.find(contact_id) rescue nil
      contact.try(:geocode_and_save)
    end
  end
end
