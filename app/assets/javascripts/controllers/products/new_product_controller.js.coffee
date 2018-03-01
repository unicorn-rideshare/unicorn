module = angular.module('unicornApp.controllers')

module.controller 'NewProductCtrl', ['$scope', '$location', 'Product', 'companyPreference', 'flashService',
  ($scope, $location, Product, companyPreference, flashService) ->

    $scope.data = {}

    $scope.submit = ->
      productParams =
        company_id: companyPreference.get()
        gtin: $scope.gtin
        tier: $scope.tier
        data:
          name: $scope.data.name
          style: $scope.data.style
          size: $scope.data.size
          color: $scope.data.color
          price: $scope.data.price
          unit_of_measure: $scope.data.unit_of_measure
          revenue_per_unit: $scope.revenue_per_unit
      product = Product.save(productParams)
      product.$promise.then ->
        flashService.success('Product created successfully')
        $location.path('/products')
]
