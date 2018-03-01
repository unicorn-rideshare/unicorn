module = angular.module('unicornApp.controllers')

module.controller 'NewProviderOriginAssignmentCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Origin', 'Provider', 'ProviderOriginAssignment', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Origin, Provider, ProviderOriginAssignment, companyPreference, flashService) ->

    $scope.marketId = parseInt($routeParams.market_id)
    $scope.originId = parseInt($routeParams.origin_id)
    $scope.origin = Origin.get market_id: $scope.marketId, id: $scope.originId
    $scope.providers = Provider.query company_id: companyPreference.get()

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
        provider_id: $scope.provider
        start_date: $scope.startDate
        end_date: $scope.endDate

      providerOriginAssignment = ProviderOriginAssignment.save(params)
      providerOriginAssignment.$promise.then ->
        flashService.success('Provider origin assignment created successfully')
        $location.path('/markets/' + $scope.marketId + '/origins/' + $scope.originId + '/edit')
]
