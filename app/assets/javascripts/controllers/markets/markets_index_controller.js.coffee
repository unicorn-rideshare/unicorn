module = angular.module('unicornApp.controllers')

module.controller 'MarketsIndexCtrl', ['$scope', '$controller', 'Market', 'companyPreference',
  ($scope, $controller, Market, companyPreference) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Market
    $scope.collectionName = 'markets'

    $scope.markets = []

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
