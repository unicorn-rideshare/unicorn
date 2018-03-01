module = angular.module('unicornApp.controllers')

module.controller 'NewRouteCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Market', 'Origin', 'DispatcherOriginAssignment', 'ProviderOriginAssignment', 'Route', 'companyPreference', 'flashService',
  ($scope, $filter, $location, $routeParams, Market, Origin, DispatcherOriginAssignment, ProviderOriginAssignment, Route, companyPreference, flashService) ->

    $scope.date = new Date()

    $scope.marketId = null
    $scope.originId = null

    $scope.providerOriginAssignments = []

    $scope.$watch 'marketId', ->
      $scope.fetchOrigins()

    $scope.$watch 'originId', ->
      $scope.fetchDispatcherOriginAssignments()
      $scope.fetchProviderOriginAssignments()

    $scope.$watch 'date', ->
      $scope.fetchDispatcherOriginAssignments()
      $scope.fetchProviderOriginAssignments()

    $scope.openDatePicker = (key, event) ->
      event.preventDefault()
      event.stopPropagation()
      $scope[key] = true

    $scope.fetchMarkets = ->
      markets = Market.query company_id: companyPreference.get()
      markets.$promise.then ->
        $scope.markets = markets
        $scope.marketId = $scope.markets[0].id if $scope.markets.length == 1

    $scope.fetchOrigins = ->
      return unless $scope.marketId
      origins = Origin.query market_id: $scope.marketId
      origins.$promise.then ->
        $scope.origins = origins
        $scope.originId = $scope.origins[0].id if $scope.origins.length == 1

    $scope.fetchProviderOriginAssignments = ->
      return unless $scope.marketId && $scope.originId
      providerOriginAssignments = ProviderOriginAssignment.query market_id: $scope.marketId, origin_id: $scope.originId, start_date: $scope.date.toISODateString(), status: 'scheduled,in_progress'
      providerOriginAssignments.$promise.then ->
        $scope.providerOriginAssignments = providerOriginAssignments
        $scope.providerOriginAssignmentId = providerOriginAssignments[0].id if providerOriginAssignments && providerOriginAssignments.length > 0

    $scope.fetchDispatcherOriginAssignments = ->
      return unless $scope.marketId && $scope.originId
      dispatcherOriginAssignments = DispatcherOriginAssignment.query market_id: $scope.marketId, origin_id: $scope.originId, start_date: $scope.date.toISODateString(), status: 'scheduled,in_progress'
      dispatcherOriginAssignments.$promise.then ->
        $scope.dispatcherOriginAssignments = dispatcherOriginAssignments
        $scope.dispatcherOriginAssignmentId = dispatcherOriginAssignments[0].id if dispatcherOriginAssignments && dispatcherOriginAssignments.length > 0

    $scope.submit = ->
      routeParams =
        company_id: companyPreference.get()
        date: $scope.date.toISODateString()
        dispatcher_origin_assignment_id: $scope.dispatcherOriginAssignmentId
        provider_origin_assignment_id: $scope.providerOriginAssignmentId
      route = Route.save(routeParams)
      route.$promise.then ->
        flashService.success('Route created successfully')
        $location.path('/routes')

    $scope.fetchMarkets()
]
