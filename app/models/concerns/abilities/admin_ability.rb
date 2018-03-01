module AdminAbility
  extend ActiveSupport::Concern

  included do
    def admin_abilities
      return unless authenticable && authenticable.is_a?(User)
    end
  end
end
