# ProviderBulkDailyPayoutJob enqueues a daily
# payout job for every eligible Provider.
class ProviderBulkDailyPayoutJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform()
      new(Date.today.iso8601).process
    end
  end

  def initialize(date)
    @date = Date.parse(date)
  end

  def process
    Provider.unscoped.all.each do |provider|
    	Resque.enqueue(ProviderDailyPayoutJob, provider.id, @date.iso8601)
    end
  end
end
