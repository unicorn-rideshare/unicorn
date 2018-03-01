class JwtToken < ActiveRecord::Base

  belongs_to :company
  belongs_to :provider
  belongs_to :user

  validates_presence_of :token
end
