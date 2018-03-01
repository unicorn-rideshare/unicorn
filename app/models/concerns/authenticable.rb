module Authenticable
  extend ActiveSupport::Concern

  included do
    has_many :tokens, as: :authenticable, dependent: :destroy
  end
end
