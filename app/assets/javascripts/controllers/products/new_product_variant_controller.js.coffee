module = angular.module('unicornApp.controllers')

module.controller 'NewProductVariantCtrl', ['$scope', '$location', '$routeParams', 'Product', 'companyPreference', 'flashService',
  ($scope, $location, $routeParams, Product, companyPreference, flashService) ->

    $scope.showActivity = true

    product = Product.get id: $routeParams.id, ->
      $scope.product = product
      $scope.showActivity = false

    $scope.submit = ->
      productParams =
        product_id: $scope.product.id
        company_id: companyPreference.get()
        gtin: $scope.product.gtin
        tier: $scope.product.tier
        data:
          name: $scope.product.data.name
          style: $scope.product.data.style
          size: $scope.product.data.size
          color: $scope.product.data.color
          price: $scope.product.data.price
          unit_of_measure: $scope.product.data.unit_of_measure
      product = Product.save(productParams)
      product.$promise.then ->
        flashService.success('Product created successfully')
        $location.path('/products/' + $scope.product.id + '/edit')
]
