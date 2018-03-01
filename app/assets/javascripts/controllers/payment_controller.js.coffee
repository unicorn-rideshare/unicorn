module = angular.module('unicornApp.controllers')

module.controller 'PaymentCtrl', ['$scope', '$modalInstance', 'Company', 'SubscriptionPlans', 'SupportsCouponCodes', 'flashService', 'company',
  ($scope, $modalInstance, Company, SubscriptionPlans, SupportsCouponCodes, flashService, company) ->

    $scope.showActivity = false

    $scope.title = 'Billing Details'
    $scope.submitButtonText = if company.stripe_credit_card_id then 'Update Credit Card' else 'Add Credit Card'
    $scope.hasExistingPaymentMethod = false
    $scope.hasExistingSubscription = false
    $scope.requireSubscription = false
    $scope.subscriptionPlans = SubscriptionPlans
    $scope.subscriptionPlanId = null
    $scope.supportsCouponCodes = SupportsCouponCodes

    $scope.fetchBillingDetails = ->
      $scope.showActivity = true
      c = Company.get id: company.id, include_stripe_customer: true, ->
        hasExistingCard = c.stripe_customer && c.stripe_customer.sources && c.stripe_customer.sources.data && c.stripe_customer.sources.data.length > 0
        card = c.stripe_customer.sources.data[0] if hasExistingCard
        if card
          $scope.existingCardType = card.brand
          $scope.existingCardLastFour = card.last4
          expMonth = if card.exp_month < 10 then '0' + card.exp_month else card.exp_month
          $scope.existingCardExpiration = expMonth + '/' + card.exp_year
          $scope.hasExistingPaymentMethod = true
        hasExistingSubscription = c.stripe_customer && c.stripe_customer.subscriptions && c.stripe_customer.subscriptions.data && c.stripe_customer.subscriptions.data.length > 0
        subscription = c.stripe_customer.subscriptions.data[0] if hasExistingSubscription
        $scope.subscription = subscription.id if subscription
        $scope.hasExistingSubscription = !!$scope.subscription
        $scope.subscriptionPlanId = subscription.plan.id if subscription && subscription.plan

        $scope.showActivity = false

    $scope.handleStripe = (status, response) ->
      $scope.subscriptionPlanId = angular.element('select#subscription-plan-id').val()
      $scope.subscriptionPlanId = $scope.subscriptionPlanId.replace(/^string:/i, '') if $scope.subscriptionPlanId
      company.stripe_plan_id = $scope.subscriptionPlanId if $scope.subscriptionPlanId && (!$scope.hasExistingSubscription || $scope.subscription.plan.id != $scope.subscriptionPlanId)

      $scope.couponCode = angular.element('input#coupon-code').val()
      $scope.couponCode = $scope.couponCode.replace(/^string:/i, '') if $scope.couponCode && $scope.couponCode.length > 0
      company.stripe_coupon_code = $scope.couponCode if $scope.couponCode

      if response.error
        $scope.handleStripeError(response.error)
      else
        $scope.handleStripeSuccess(response)

    $scope.handleStripeError = (error) ->
      flashService.warning(error.message)

    $scope.handleStripeSuccess = (response) ->
      company.stripe_card_token = response.id

      company.$update().then ->
        flashService.success('Your credit card was updated successfully.')
        $modalInstance.dismiss()

    $scope.cancel = ->
      $modalInstance.dismiss()

    $scope.fetchBillingDetails()
]
