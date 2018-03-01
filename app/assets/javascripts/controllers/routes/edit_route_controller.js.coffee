module = angular.module('unicornApp.controllers')

module.controller 'EditRouteCtrl', [
  '$scope', '$filter', '$location', '$routeParams', 'Route', 'flashService',
  ($scope, $filter, $location, $routeParams, Route, flashService) ->

    $scope.showActivity = true

    $scope.isCancellable = false
    $scope.hideWorkOrderStatusFilter = true

    route = Route.get id: $routeParams.id, include_dispatcher_origin_assignment: true, include_provider_origin_assignment: true, include_work_orders: true, ->
      $scope.route = route
      $scope.isSchedulable = $scope.route.status == 'awaiting_schedule'
      $scope.isCancellable = ['canceled'].indexOf($scope.route.status) == -1
      $scope.showActivity = false

    $scope.submit = ->
      promise = $scope.route.$update()
      promise.then ->
        flashService.success('Route was successfully updated')
        $location.path('/routes')

    $scope.scheduleRoute = ->
      $scope.route.status = 'scheduled'
      $scope.route.$update().then ->
        flashService.warning('Route has been scheduled')
        $location.path('/routes')

    $scope.cancelRoute = ->
      $scope.route.status = 'canceled'
      $scope.route.$update().then ->
        flashService.warning('Route has been cancelled')
        $location.path('/routes')
]
