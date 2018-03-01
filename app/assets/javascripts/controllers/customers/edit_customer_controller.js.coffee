module = angular.module('unicornApp.controllers')

module.controller 'EditCustomerCtrl', ['$scope', '$location', '$routeParams', 'Customer', 'flashService',
 ($scope, $location, $routeParams, Customer, flashService) ->

   $scope.showActivity = true

   customer = Customer.get id: $routeParams.id, ->
     $scope.customer = customer
     $scope.showActivity = false

   $scope.submit = ->
     promise = $scope.customer.$update()
     promise.then ->
       flashService.success('Customer was successfully updated')
       $location.path('/customers')
]
