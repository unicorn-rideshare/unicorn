module = angular.module('unicornApp.controllers')

module.controller 'WorkOrdersIndexCtrl', ['$scope', '$filter', '$controller', 'WorkOrder', 'companyPreference', 'preferences',
  ($scope, $filter, $controller, WorkOrder, companyPreference, preferences) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = WorkOrder
    $scope.collectionName = 'workOrders'

    $scope.showAbandonedFilter = true
    $scope.showStandalone = preferences.get('x-show-standalone-work-orders') || false
    $scope.workOrders = []

    $scope.$watch 'showStandalone', (newValue, oldValue) ->
      return if newValue == undefined
      preferences.set('x-show-standalone-work-orders', newValue) if newValue
      preferences.delete('x-show-standalone-work-orders') unless newValue
      $scope.query() if newValue != oldValue

    $scope.filter =
      status:
        scheduled: true

    for filter in ['filter.status.abandoned',
                   'filter.status.awaiting_schedule',
                   'filter.status.scheduled',
                   'filter.status.pending_acceptance',
                   'filter.status.timed_out',
                   'filter.status.en_route',
                   'filter.status.arriving',
                   'filter.status.in_progress',
                   'filter.status.paused',
                   'filter.status.canceled',
                   'filter.status.completed']
      $scope.$watch filter, (newValue, oldValue) ->
        $scope.query() if newValue != oldValue

    for filter in ['filter.onOrAfter',
                   'filter.onOrBefore']
      $scope.$watch filter, (newValue, oldValue) ->
        $scope.query() if newValue != oldValue

    $scope.queryParams = ->
      statusFilters = []
      for key, value of $scope.filter.status
        statusFilters.push(key) if value
      $scope.filter.status.scheduled = true if statusFilters.length == 0

      params =
        status: if statusFilters.length == 0 then 'scheduled' else statusFilters.join(',')

      params.company_id = companyPreference.get() unless $scope.showStandalone

      dateRange = $scope.getActiveDateRange()
      params.date_range = dateRange if dateRange

      params

    $scope.toggle = ($event, picker) ->
      isOpen = $scope[picker]
      $event.preventDefault()
      $event.stopPropagation()
      $scope.onOrAfterOpened = $scope.onOrBeforeOpened = false
      $scope[picker] = !isOpen

    $scope.getActiveDateRange = ->
      dateFormatter = $filter('date')
      filter = $scope.filter || {}
      filtersOnOrAfter = filter.onOrAfter != undefined  && filter.onOrAfter != null
      filtersOnOrBefore = filter.onOrBefore != undefined  && filter.onOrBefore != null
      return null if !filtersOnOrAfter && !filtersOnOrBefore
      onOrAfter = if filtersOnOrAfter then dateFormatter(filter.onOrAfter, 'yyyy-MM-dd') else ''
      onOrBefore = if filtersOnOrBefore then dateFormatter(filter.onOrBefore, 'yyyy-MM-dd') else ''
      onOrAfter + '..' + onOrBefore

    $scope.query()
]
