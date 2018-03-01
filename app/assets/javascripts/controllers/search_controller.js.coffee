module = angular.module('unicornApp.controllers')

module.controller 'SearchCtrl', ['$scope', '$controller', '$element', '$injector',
  ($scope, $controller, $element, $injector) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = null
    $scope.collectionName = 'results'

    $scope.queryString = ''

    $scope.watchPage = false
    $scope.hasNextPage = true

    $scope.queryInputIsBlurred = true
    $scope.hideDefaultSearchResults = false

    $scope.results = []
    $scope.allResults = []

    $scope.$watch 'collectionClass', ->
      if $scope.collectionClass && typeof($scope.collectionClass) == 'string'
        $scope.collectionClass = $injector.get($scope.collectionClass)

    $scope.$watch 'queryString', (newValue, oldValue) ->
      $scope.$emit($scope.onQueryChangedMessage, newValue) if newValue != oldValue && $scope.onQueryChangedMessage
      $scope.reset() if oldValue != newValue

      if $scope.queryString
        if $scope.queryString.length == 0
          $scope.reset()
        else
          $scope.search()
      else
        $scope.reset()

    $scope.resultSelected = (result) ->
      $scope.$emit($scope.onResultSelectedMessage, result) if $scope.onResultSelectedMessage
      $scope.results = []
      $scope.queryString = ''

    $scope.$watch 'updateQueryInputMessage', ->
      if $scope.updateQueryInputMessage
        $scope.$on $scope.updateQueryInputMessage, (event, query) ->
          $scope.queryString = query
          input = angular.element($element.find('input[type=text]')[0])
          input.val($scope.queryString)
          input.focus()

    $scope.$watch 'updateQueryInputPlaceholderMessage', ->
      if $scope.updateQueryInputPlaceholderMessage
        $scope.$on $scope.updateQueryInputPlaceholderMessage, (event, placeholder) ->
          $scope.placeholder = placeholder

    $scope.changedQueryString = (e) ->
      $scope.queryString = angular.element(e.target).val()
      $scope.$emit($scope.onQueryChangedMessage, $scope.queryString) if $scope.onQueryChangedMessage
      true

    $scope.focusedQueryStringInput = (e) ->
      fn = -> $scope.queryInputIsBlurred = false
      setTimeout(fn, 20)
      true

    $scope.blurredQueryStringInput = (e) ->
      fn = -> $scope.queryInputIsBlurred = true
      setTimeout(fn, 20)
      true

    $scope.reset = ->
      $scope.results = []
      $scope.allResults = []
      $scope.page = 0
      $scope.hasNextPage = true

    $scope.search = ->
      return unless $scope.hasNextPage

      $scope.allResults = [] if $scope.page == 0
      $scope.page++

      promise = $scope.query()
      promise.then ->
        for result in $scope.results
          $scope.allResults.push(result)
        $scope.hasNextPage = $scope.results.length == $scope.rpp
        $scope.$emit($scope.onResultsReceivedMessage, { status: $scope.status, page: $scope.page, rpp: $scope.rpp, results: $scope.results, allResults: $scope.allResults, hasNextPage: $scope.hasNextPage, totalResultsCount: $scope.totalItems }) if $scope.onResultsReceivedMessage

    $scope.displayNameForResult = (result) ->
      return result unless $scope.resultTitleKey
      for path in $scope.resultTitleKey.split('.')
        result = result[path]
      result
]
