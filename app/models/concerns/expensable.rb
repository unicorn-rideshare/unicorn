module Expensable
  extend ActiveSupport::Concern

  included do
    has_many :expenses, as: :expensable, dependent: :destroy
  end
end
