module = angular.module('unicornApp.controllers')

module.controller 'EditProviderCtrl', ['$scope', '$location', '$routeParams', 'Provider', 'Category', 'companyPreference', 'flashService',
 ($scope, $location, $routeParams, Provider, Category, companyPreference, flashService) ->

   $scope.showActivity = true

   $scope.providerCategories = {}
   $scope.providerCategoryIds = []

   categories = Category.query company_id: companyPreference.get(), ->
     $scope.categories = categories
     $scope.showActivity = !$scope.provider

   provider = Provider.get id: $routeParams.id, ->
     $scope.provider = provider
     for categoryId in $scope.provider.category_ids
       $scope.providerCategories[categoryId] = true
     $scope.showActivity = !$scope.categories

    $scope.$watchCollection 'providerCategories', ->
      if $scope.providerCategories
        $scope.providerCategoryIds = []
        for id, status of $scope.providerCategories
          $scope.providerCategoryIds.push(id) if status

   $scope.submit = ->
     $scope.provider.category_ids = $scope.providerCategoryIds
     promise = $scope.provider.$update()
     promise.then ->
       flashService.success('Provider was successfully updated')
       $location.path('/providers')
]
