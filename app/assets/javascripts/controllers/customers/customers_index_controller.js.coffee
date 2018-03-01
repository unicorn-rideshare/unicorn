module = angular.module('unicornApp.controllers')

module.controller 'CustomersIndexCtrl', ['$scope', '$controller', 'Customer', 'companyPreference',
  ($scope, $controller, Customer, companyPreference) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Customer
    $scope.collectionName = 'customers'

    $scope.customers = []

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
