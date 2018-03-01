module = angular.module('unicornApp.controllers')

module.controller 'ResetPasswordCtrl', ['$scope', '$routeParams', '$location', 'authentication', 'flashService',
  ($scope, $routeParams, $location, authentication, flashService) ->

    $scope.reset_password_token = $routeParams.t

    $scope.resetPassword = ->
      $scope.showActivity = true
      flashService.clear()
      authentication.resetPassword($scope).$promise.then ->
        $scope.showActivity = false
        if $scope.reset_password_token
          flashService.success('Your password has been reset.')
          $location.path('/login')
        else
          flashService.success('Reset password instructions have been delivered to ' + $scope.email + '.')
      .catch ->
        $scope.showActivity = false
        flashService.danger('Attempt to reset password failed. Verify you typed your email address correctly.')
]
