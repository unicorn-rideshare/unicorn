module = angular.module('unicornApp.controllers')

module.controller 'NewOriginCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, flashService) ->

    $scope.marketId = $routeParams.market_id

    $scope.submit = ->
      originParams = $scope.origin
      originParams.market_id = $routeParams.market_id
      origin = Origin.save(originParams)
      origin.$promise.then ->
        flashService.success('Origin created successfully')
        $location.path('/markets/' + $scope.marketId + '/origins')
]
