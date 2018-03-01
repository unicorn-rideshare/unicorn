class Wallet < ActiveRecord::Base
  belongs_to :user

  validates :type, inclusion: %w(eth)
  validates :address, presence: true
  validates :wallet_id, presence: true

  class << self
    def inheritance_column
      'subclass'
    end
  end
end
