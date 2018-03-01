module = angular.module('unicornApp.controllers')

module.controller 'EditMarketCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Market', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Market, companyPreference, flashService) ->

    $scope.showActivity = true

    market = Market.get id: $routeParams.id, ->
      $scope.market = market
      $scope.showActivity = false

    $scope.submit = ->
      promise = $scope.market.$update()
      promise.then ->
        flashService.success('Market was successfully updated')
        $location.path('/markets')
]
