module = angular.module('unicornApp.controllers')

module.controller 'EditDispatcherOriginAssignmentCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'Dispatcher', 'DispatcherOriginAssignment', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, Dispatcher, DispatcherOriginAssignment, companyPreference, flashService) ->

    $scope.showActivity = true

    $scope.marketId = parseInt($routeParams.market_id)
    $scope.originId = parseInt($routeParams.origin_id)
    dispatcherOriginAssignment = DispatcherOriginAssignment.get market_id: $scope.marketId, origin_id: $scope.originId, id: $routeParams.id, ->
      $scope.dispatcherOriginAssignment = dispatcherOriginAssignment
      $scope.showActivity = false

    $scope.$watch 'dispatcherOriginAssignment.start_date', (newValue, oldValue) ->
      if oldValue != undefined
        $scope.dispatcherOriginAssignment.end_date = $scope.dispatcherOriginAssignment.start_date

    $scope.$watch 'dispatcherOriginAssignment.end_date', (newValue, oldValue) ->
      if oldValue != undefined
        if $scope.dispatcherOriginAssignment.start_date && $scope.dispatcherOriginAssignment.end_date
          if $scope.dispatcherOriginAssignment.end_date.getTime() < $scope.dispatcherOriginAssignment.start_date.getTime()
            $scope.dispatcherOriginAssignment.end_date = $scope.dispatcherOriginAssignment.start_date

    $scope.openDatePicker = (key, event) ->
      event.preventDefault()
      event.stopPropagation()
      $scope[key] = true

    $scope.submit = ->
      promise = $scope.dispatcherOriginAssignment.$update(market_id: $scope.marketId, origin_id: $scope.originId)
      promise.then ->
        flashService.success('Dispatcher origin assignment was successfully updated')
        $location.path('/markets/' + $scope.marketId + '/origins/' + $scope.originId + '/edit')
]
