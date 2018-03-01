module = angular.module('unicornApp.controllers')

module.controller 'ProvidersIndexCtrl', ['$scope', '$controller', 'Provider', 'companyPreference',
  ($scope, $controller, Provider, companyPreference) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Provider
    $scope.collectionName = 'providers'

    $scope.providers = []

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
