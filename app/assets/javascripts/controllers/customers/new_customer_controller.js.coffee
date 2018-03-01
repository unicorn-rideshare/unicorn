module = angular.module('unicornApp.controllers')

module.controller 'NewCustomerCtrl', ['$scope', '$location', 'Customer', 'flashService', 'companyPreference',
  ($scope, $location, Customer, flashService, companyPreference) ->
    $scope.customer = new Customer(company_id: companyPreference.get())

    $scope.submit = ->
      promise = $scope.customer.$save()
      promise.then ->
        flashService.success('Customer was successfully created')
        $location.path('/customers')

]
