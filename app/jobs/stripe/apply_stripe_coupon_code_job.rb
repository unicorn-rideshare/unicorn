class ApplyStripeCouponCodeJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_coupon_code)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_coupon_code

      stripe_customer = instance.try(:stripe_customer)
      return unless stripe_customer

      stripe_customer.coupon = stripe_coupon_code
      stripe_customer.save
    end
  end
end
