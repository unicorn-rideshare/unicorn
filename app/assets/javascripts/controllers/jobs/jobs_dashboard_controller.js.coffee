module = angular.module('unicornApp.controllers')

module.controller 'JobsDashboardCtrl', ['$scope', '$controller', '$location', 'companyPreference', 'Job',
  ($scope, $controller, $location, companyPreference, Job) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Job
    $scope.collectionName = 'jobs'

    $scope.jobs = []

    $scope.filter =
      status:
        configuring: true
        in_progress: true
        pending_completion: true

    for filter in ['filter.status.configuring',
                   'filter.status.in_progress',
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

    $scope.viewJob = (job) ->
      $location.path('/jobs/' + job.id)

    $scope.queryParams = ->
      statusFilters = []
      for key, value of $scope.filter.status
        statusFilters.push(key) if value
      params =
        include_customer: true
        include_supervisors: true
        company_id: companyPreference.get()
        status: statusFilters.join(',')
      params

    $scope.query()
]
