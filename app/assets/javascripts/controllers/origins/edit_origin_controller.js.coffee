module = angular.module('unicornApp.controllers')

module.controller 'EditOriginCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, companyPreference, flashService) ->

    $scope.showActivity = true

    $scope.marketId = $routeParams.market_id
    origin = Origin.get(market_id: $scope.marketId, id: $routeParams.id)
    origin.$promise.then ->
      $scope.origin = origin
      $scope.showActivity = false

    $scope.submit = ->
      promise = $scope.origin.$update(market_id: $scope.marketId)
      promise.then ->
        flashService.success('Origin was successfully updated')
        $location.path('/markets/' + $routeParams.market_id + '/origins')
]
