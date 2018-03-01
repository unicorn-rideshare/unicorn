class RequeueFailuresJob
  @queue = :high

  class << self
    def perform
      return unless Resque::Failure.count > 0
      
      Resque::Failure.count.times do |i|
        Resque::Failure.requeue(i)
      end
      
      Resque::Failure.clear
    end
  end
end
