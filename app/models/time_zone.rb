class TimeZone
  class << self
    def all
      ActiveSupport::TimeZone.all
    end

    def find(name)
      ActiveSupport::TimeZone[name]
    end
  end
end
