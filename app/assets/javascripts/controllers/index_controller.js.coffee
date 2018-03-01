module = angular.module('unicornApp.controllers')

module.controller 'IndexCtrl', [ '$window', '$q', '$scope',
  ($window, $q, $scope) ->
    $scope.page = 1
    $scope.rpp = 25
    $scope.items = null
    $scope.totalItems = null
    $scope.watchPage = true
    $scope.status = 0
    $scope.resource = null
    $scope.execTimeMs = null

    $scope.showActivity = false

    $scope.$watch 'page', (newValue, oldValue) ->
      query = $scope.watchPage && newValue != oldValue
      $scope.query() if query
      $window.scrollTo(0, 0) if query

    $scope.$watch 'resource', ->
      $scope.status = 0 unless $scope.resource

    $scope.queryParams = ->
      { }

    $scope.cancel = ->
      $scope.resource.$cancelRequest() if $scope.resource
      $scope.resource = null

    $scope.query = () ->
      $scope.showActivity = true
      $scope.cancel()

      startTimestampMillis = new Date().getTime()

      params = $scope.queryParams()
      params.page = $scope.page
      params.rpp = $scope.rpp

      $scope.resource = $scope.collectionClass.paginate(params)
      if $scope.resource && $scope.resource.$promise
        $scope.resource.$promise.then ->
          $scope.execTimeMs = new Date().getTime() - startTimestampMillis
          if $scope.resource && $scope.resource.status > 0
            $scope.status = $scope.resource.status
            $scope[$scope.collectionName] = $scope.resource.results if $scope.collectionName
            $scope.totalItems = $scope.resource.totalResults
          $scope.showActivity = false
          $scope.resource = null
        .catch ->
          $scope.resource = null

      $scope.resource.$promise
]
