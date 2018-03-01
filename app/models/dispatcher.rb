class Dispatcher < ActiveRecord::Base
  include Contactable

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  has_many :origin_assignments, class_name: DispatcherOriginAssignment.name
  has_many :routes, through: :origin_assignments

  belongs_to :user
  validates :user_id, uniqueness: { scope: :company_id }, allow_nil: true
  validates :user_id, readonly: true, on: :update

  before_validation :require_user, on: :create

  after_save :update_permissions, on: :create

  default_scope { includes(:contact, :routes, :user).order('id') }

  def delete
    self.contact.try(:delete)
    self.user.roles.reload.each do |role|
      resource = role.resource
      remove_role = resource && (resource.respond_to?(:company_id) && resource.company_id == self.company_id || resource == self.company)
      remove_role = resource.is_a?(DispatcherOriginAssignment) && resource.origin.market.company_id == self.company_id unless remove_role
      self.user.remove_role(role.name.to_sym, resource) if remove_role
    end if self.user
    super
  end

  def require_contact_time_zone?
    true
  end

  private

  def require_user
    self.user = User.create(name: self.contact.name,
                            email: self.contact.email,
                            password: SecureRandom.uuid) unless self.user || self.contact.nil?
  end

  def update_permissions
    user.add_role(:dispatcher, company) if user
  end
end
