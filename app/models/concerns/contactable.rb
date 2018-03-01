module Contactable
  extend ActiveSupport::Concern

  included do
    has_one :contact, as: :contactable, dependent: :destroy
    accepts_nested_attributes_for :contact

    after_destroy :destroy_contact

    scope :joined_contacts, -> {
      clazz = self
      joins("INNER JOIN contacts ON contacts.contactable_id = #{clazz.name.underscore.pluralize}.id AND contacts.contactable_type = '#{clazz.name}'")
    }

    scope :query_contacts_by_name, ->(query) {
      joined_contacts.where('contacts.name ILIKE ?', "%#{query}%")
    }

    private

    def destroy_contact
      contact.try(:destroy)
    end
  end
end
