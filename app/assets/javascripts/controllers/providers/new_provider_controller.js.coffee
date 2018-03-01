module = angular.module('unicornApp.controllers')

module.controller 'NewProviderCtrl', ['$scope', '$location', 'Provider', 'Category', 'flashService', 'companyPreference',
  ($scope, $location, Provider, Category, flashService, companyPreference) ->

    $scope.showActivity = true

    $scope.provider = new Provider(company_id: companyPreference.get())

    $scope.providerCategories = {}
    $scope.providerCategoryIds = []

    categories = Category.query company_id: companyPreference.get(), ->
      $scope.categories = categories
      $scope.showActivity = false

    $scope.$watchCollection 'providerCategories', ->
      if $scope.providerCategories
        $scope.providerCategoryIds = []
        for id, status of $scope.providerCategories
          $scope.providerCategoryIds.push(id) if status

    $scope.submit = ->
      $scope.provider.category_ids = $scope.providerCategoryIds
      promise = $scope.provider.$save()
      promise.then ->
        flashService.success('Provider was successfully created')
        $location.path('/providers')

]
