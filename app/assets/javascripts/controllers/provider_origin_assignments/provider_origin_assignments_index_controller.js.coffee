module = angular.module('unicornApp.controllers')

module.controller 'ProviderOriginAssignmentsIndexCtrl', ['$scope', '$controller', '$routeParams', '$filter', 'ProviderOriginAssignment',
  ($scope, $controller, $routeParams, $filter, ProviderOriginAssignment) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = ProviderOriginAssignment
    $scope.collectionName = 'providerOriginAssignments'

    $scope.date = new Date()

    $scope.marketId = $routeParams.market_id
    $scope.originId = $routeParams.id

    $scope.providerOriginAssignments = []

    $scope.queryParams = ->
      params =
        market_id: $scope.marketId
        origin_id: $scope.originId
        status: $scope.status
      date = $scope.getFormattedDateQueryParameter()
      params.start_date = date if date
      params

    $scope.getFormattedDateQueryParameter= ->
      return null if !$scope.date
      dateFormatter = $filter('date')
      dateFormatter($scope.date, 'yyyy-MM-dd')

    $scope.cancelProviderOriginAssignment = (providerOriginAssignment) ->
      ProviderOriginAssignment.delete(id: providerOriginAssignment.id, market_id: $scope.marketId, origin_id: $routeParams.id).$promise.then ->
        $scope.providerOriginAssignments.splice($scope.providerOriginAssignments.indexOf(providerOriginAssignment), 1)

    $scope.query()
]
