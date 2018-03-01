module = angular.module('unicornApp.controllers')

module.controller 'NewMarketCtrl', [
  '$scope', '$filter', '$location', 'Market', 'companyPreference', 'flashService',
  ($scope, $filter, $location, Market, companyPreference, flashService) ->

    $scope.submit = ->
      marketParams =
        company_id: companyPreference.get(),
        name: $scope.name
      market = Market.save(marketParams)
      market.$promise.then ->
        flashService.success('Market created successfully')
        $location.path('/markets')
]
