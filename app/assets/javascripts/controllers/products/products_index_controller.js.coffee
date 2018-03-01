module = angular.module('unicornApp.controllers')

module.controller 'ProductsIndexCtrl', ['$scope', '$controller', 'companyPreference', 'Product',
  ($scope, $controller, companyPreference, Product) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Product
    $scope.collectionName = 'products'

    $scope.products = []

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
