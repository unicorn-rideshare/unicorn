module = angular.module('unicornApp.controllers')

module.controller 'EditProductCtrl', ['$scope', '$location', '$routeParams', 'Product', 'flashService',
 ($scope, $location, $routeParams, Product, flashService) ->

   $scope.showActivity = true

   product = Product.get id: $routeParams.id, ->
     $scope.product = product
     $scope.showActivity = false

   $scope.submit = ->
     promise = $scope.product.$update()
     promise.then ->
       flashService.success('Product was successfully updated')
       $location.path('/products')
]
