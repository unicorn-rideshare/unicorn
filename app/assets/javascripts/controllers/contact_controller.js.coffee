module = angular.module('unicornApp.controllers')

module.controller 'ContactCtrl', ['$scope', '$routeParams', 'recaptchaSiteKey', 'vcRecaptchaService', 'flashService', 'Recaptcha', 'Lead',
  ($scope, $routeParams, recaptchaSiteKey, vcRecaptchaService, flashService, Recaptcha, Lead) ->
    $scope.recaptchaSiteKey = recaptchaSiteKey
    $scope.recaptchaWidgetId = null
    $scope.recaptchaResponse = null

    $scope.pendingCaptcha = false
    $scope.contactSucceeded = false

    $scope.model = { recaptchaSiteKey: $scope.recaptchaSiteKey }

    $scope.recaptchaCreated = (widgetId) ->
      $scope.recaptchaWidgetId = widgetId

    $scope.recaptchaSucceeded = (response) ->
      $scope.recaptchaResponse = response
      $scope.submit()

    $scope.recaptchaExpired = ->
      $scope.recaptchaResponse = null

    $scope.submitCaptcha = ->
      $scope.showActivity = true

      leadParams =
        recaptcha_response: $scope.recaptchaResponse
        subject: $scope.subject
        message: $scope.message
        contact_attributes:
          name: $scope.name
          email: $scope.email
          phone: $scope.phone
      lead = new Lead(leadParams).$save()
      lead.then ->
        $scope.showActivity = false
        $scope.contactSucceeded = true
        $scope.pendingCaptcha = false
        $scope.recaptchaResponse = null

        flashService.success('Thank you for reaching out! We will be in touch soon.')
      .catch ->
        flashService.warning('Captcha validation failed')
        $scope.recaptchaResponse = null

    $scope.submit = ->
      flashService.clear()

      if !$scope.pendingCaptcha
        $scope.pendingCaptcha = true
        return
      else if $scope.recaptchaResponse
        $scope.submitCaptcha()
        return
]
