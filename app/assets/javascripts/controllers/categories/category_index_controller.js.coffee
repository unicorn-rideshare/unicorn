module = angular.module('unicornApp.controllers')

module.controller 'CategoriesIndexCtrl', ['$scope', '$controller', 'companyPreference', 'Category',
  ($scope, $controller, companyPreference, Category) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Category
    $scope.collectionName = 'categories'

    $scope.categories = []

    $scope.modalInstance = null

    $scope.queryParams = ->
      { company_id: companyPreference.get() }

    $scope.query()
]
