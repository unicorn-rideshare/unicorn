class Expense < ActiveRecord::Base
  include Attachable
  include StateMachine

  belongs_to :expensable, polymorphic: true
  validates :expensable_id, readonly: true, on: :update
  validates :expensable_type, readonly: true, on: :update

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  aasm column: :status, whiny_transitions: false do
    state :submitted, initial: true
  end
end
