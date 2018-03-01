module = angular.module('unicornApp.controllers')

module.controller 'EditProviderOriginAssignmentCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'Provider', 'ProviderOriginAssignment', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, Provider, ProviderOriginAssignment, companyPreference, flashService) ->

    $scope.showActivity = true

    $scope.marketId = parseInt($routeParams.market_id)
    $scope.originId = parseInt($routeParams.origin_id)
    providerOriginAssignment = ProviderOriginAssignment.get market_id: $scope.marketId, origin_id: $scope.originId, id: $routeParams.id, ->
      $scope.providerOriginAssignment = providerOriginAssignment
      $scope.showActivity = false

    $scope.$watch 'providerOriginAssignment.start_date', (newValue, oldValue) ->
      if oldValue != undefined
        $scope.providerOriginAssignment.end_date = $scope.providerOriginAssignment.start_date

    $scope.$watch 'providerOriginAssignment.end_date', (newValue, oldValue) ->
      if oldValue != undefined
        if $scope.providerOriginAssignment.start_date && $scope.providerOriginAssignment.end_date
          if $scope.providerOriginAssignment.end_date.getTime() < $scope.providerOriginAssignment.start_date.getTime()
            $scope.providerOriginAssignment.end_date = $scope.providerOriginAssignment.start_date

    $scope.openDatePicker = (key, event) ->
      event.preventDefault()
      event.stopPropagation()
      $scope[key] = true

    $scope.submit = ->
      promise = $scope.providerOriginAssignment.$update(market_id: $scope.marketId, origin_id: $scope.originId)
      promise.then ->
        flashService.success('Provider origin assignment was successfully updated')
        $location.path('/markets/' + $scope.marketId + '/origins/' + $scope.originId + '/edit')
]
