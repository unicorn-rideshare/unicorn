module = angular.module('unicornApp.controllers')

module.controller 'DispatchersIndexCtrl', ['$scope', '$controller', 'Dispatcher', 'companyPreference',
  ($scope, $controller, Dispatcher, companyPreference) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Dispatcher
    $scope.collectionName = 'dispatchers'

    $scope.dispatchers = []

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
