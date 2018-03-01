module = angular.module('unicornApp.controllers')

module.controller 'JobsIndexCtrl', ['$scope', '$controller', 'companyPreference', 'Job',
  ($scope, $controller, companyPreference, Job) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Job
    $scope.collectionName = 'jobs'

    $scope.jobs = []

    $scope.filter =
      status:
        in_progress: true
        pending_completion: true

    for filter in ['filter.status.in_progress',
                   'filter.status.pending_completion',
                   'filter.status.canceled',
                   'filter.status.completed']
      $scope.$watch filter, (newValue, oldValue) ->
        $scope.query() if newValue != oldValue

    for filter in ['filter.onOrAfter',
                   'filter.onOrBefore']
      $scope.$watch filter, (newValue, oldValue) ->
        $scope.query() if newValue != oldValue

    $scope.modalInstance = null

    $scope.queryParams = ->
      statusFilters = []
      for key, value of $scope.filter.status
        statusFilters.push(key) if value
      params =
        company_id: companyPreference.get()
        status: statusFilters.join(',')
      params

    $scope.query()
]
