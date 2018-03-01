module = angular.module('unicornApp.controllers')

module.controller 'NewDispatcherOriginAssignmentCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'Dispatcher', 'DispatcherOriginAssignment', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, Dispatcher, DispatcherOriginAssignment, companyPreference, flashService) ->

    $scope.marketId = parseInt($routeParams.market_id)
    $scope.originId = parseInt($routeParams.origin_id)
    $scope.origin = Origin.get market_id: $scope.marketId, id: $scope.originId
    $scope.dispatchers = Dispatcher.query company_id: companyPreference.get()

    $scope.$watch 'startDate', ->
      $scope.endDate = $scope.startDate

    $scope.$watch 'endDate', ->
      if $scope.startDate && $scope.endDate
        if $scope.endDate.getTime() < $scope.startDate.getTime()
          $scope.endDate = $scope.startDate

    $scope.openDatePicker = (key, event) ->
      event.preventDefault()
      event.stopPropagation()
      $scope[key] = true

    $scope.submit = ->
      params =
        market_id: $scope.marketId
        origin_id: $scope.originId
        dispatcher_id: $scope.dispatcher
        start_date: $scope.startDate
        end_date: $scope.endDate

      dispatcherOriginAssignment = DispatcherOriginAssignment.save(params)
      dispatcherOriginAssignment.$promise.then ->
        flashService.success('Dispatcher origin assignment created successfully')
        $location.path('/markets/' + $scope.marketId + '/origins/' + $scope.originId + '/edit')
]
