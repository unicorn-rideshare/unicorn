module = angular.module('unicornApp.controllers')

module.controller 'EditDispatcherCtrl', ['$scope', '$location', '$routeParams', 'Dispatcher', 'flashService',
 ($scope, $location, $routeParams, Dispatcher, flashService) ->

   $scope.showActivity = true

   dispatcher = Dispatcher.get id: $routeParams.id, ->
     $scope.dispatcher = dispatcher
     $scope.showActivity = false

   $scope.submit = ->
     promise = $scope.dispatcher.$update()
     promise.then ->
       flashService.success('Dispatcher was successfully updated')
       $location.path('/dispatchers')
]
