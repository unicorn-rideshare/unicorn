module = angular.module('unicornApp.controllers')

module.controller 'AcceptInvitationCtrl', ['$scope', '$routeParams', 'authentication', 'flashService',
  ($scope, $routeParams, authentication, flashService) ->

    $scope.invitation_token = $routeParams.t

    $scope.acceptInvitation = ->
      $scope.showActivity = true
      flashService.clear()
      authentication.acceptInvitation($scope).catch ->
        $scope.showActivity = false
        flashService.warning('Invitation not accepted.')
]
