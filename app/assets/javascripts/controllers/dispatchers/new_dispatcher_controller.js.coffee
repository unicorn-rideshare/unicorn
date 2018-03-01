module = angular.module('unicornApp.controllers')

module.controller 'NewDispatcherCtrl', ['$scope', '$location', 'Dispatcher', 'flashService', 'companyPreference',
  ($scope, $location, Dispatcher, flashService, companyPreference) ->
    $scope.dispatcher = new Dispatcher(company_id: companyPreference.get())

    $scope.submit = ->
      promise = $scope.dispatcher.$save()
      promise.then ->
        flashService.success('Dispatcher was successfully created')
        $location.path('/dispatchers')

]
