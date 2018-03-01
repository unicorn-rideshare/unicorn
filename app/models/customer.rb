class Customer < ActiveRecord::Base
  include Contactable
  include Commentable
  include WorkOrderSettings

  attr_accessor :require_contact_time_zone

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  belongs_to :user
  validates :user_id, uniqueness: { scope: :company_id }, allow_nil: true
  validates :user_id, readonly: true, on: :update

  has_many :jobs

  has_many :work_orders

  default_scope { includes(:contact).order('id') }

  scope :query, ->(query) {
    query_contacts_by_name(query)
  }

  def communications_config
    cfg = config[:customer_communications]
    cfg.delete_if { |key, value| value.nil? } if cfg
    (cfg ? company.communications_config.merge(cfg) : company.communications_config).with_indifferent_access
  end

  def display_name
    name || contact.name
  end

  def require_contact_time_zone?
    require_contact_time_zone.nil? ? true : require_contact_time_zone
  end

  def work_order_components
    config[:components]
  end
end
