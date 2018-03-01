module = angular.module('unicornApp.controllers')

module.controller 'EditCompanyModalCtrl', ['$scope', '$modalInstance', 'company',
  ($scope, $modalInstance, company) ->

    $scope.company = company
    $scope.contact = company.contact

    $scope.titleText = if $scope.company.id then 'Edit Company Details' else 'Setup Company Details'
    $scope.submitButtonText = if $scope.company.id then 'Update Company' else 'Create Company'

    $scope.save = (company) ->
      operation = if company.id then '$update' else '$save'
      company[operation]().then -> $modalInstance.close()

    $scope.cancel = ->
      $modalInstance.dismiss()
]
