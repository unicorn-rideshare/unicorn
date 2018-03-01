module = angular.module('unicornApp.controllers')

module.controller 'LoginCtrl', ['$scope', '$routeParams', 'authentication', 'flashService',
  ($scope, $routeParams, authentication, flashService) ->

    $scope.login = ->
      $scope.showActivity = true
      flashService.clear()
      authentication.login($scope).catch ->
        $scope.showActivity = false
        flashService.danger('Login attempt failed.')
]
