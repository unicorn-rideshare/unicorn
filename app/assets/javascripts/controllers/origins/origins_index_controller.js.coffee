module = angular.module('unicornApp.controllers')

module.controller 'OriginsIndexCtrl', ['$scope', '$controller', '$routeParams', 'Origin',
  ($scope, $controller, $routeParams, Origin) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.marketId = $routeParams.market_id

    $scope.collectionClass = Origin
    $scope.collectionName = 'origins'

    $scope.origins = []

    $scope.queryParams = ->
      { market_id: $scope.marketId }

    $scope.query()
]
