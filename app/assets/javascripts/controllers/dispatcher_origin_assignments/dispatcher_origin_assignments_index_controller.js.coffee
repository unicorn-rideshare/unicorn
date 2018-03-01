module = angular.module('unicornApp.controllers')

module.controller 'DispatcherOriginAssignmentsIndexCtrl', ['$scope', '$controller', '$routeParams', '$filter', 'DispatcherOriginAssignment',
  ($scope, $controller, $routeParams, $filter, DispatcherOriginAssignment) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = DispatcherOriginAssignment
    $scope.collectionName = 'dispatcherOriginAssignments'

    $scope.date = new Date()

    $scope.marketId = $routeParams.market_id
    $scope.originId = $routeParams.id

    $scope.dispatcherOriginAssignments = []

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

    $scope.cancelDispatcherOriginAssignment = (dispatcherOriginAssignment) ->
      DispatcherOriginAssignment.delete(id: dispatcherOriginAssignment.id, market_id: $scope.marketId, origin_id: $routeParams.id).$promise.then ->
        $scope.dispatcherOriginAssignments.splice($scope.dispatcherOriginAssignments.indexOf(dispatcherOriginAssignment), 1)

    $scope.query()
]
