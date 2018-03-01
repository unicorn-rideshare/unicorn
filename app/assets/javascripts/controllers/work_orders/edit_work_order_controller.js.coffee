module = angular.module('unicornApp.controllers')

module.controller 'EditWorkOrderCtrl', ['$scope', '$location', '$routeParams', 'WorkOrder', 'Provider', 'Product', 'companyPreference', 'flashService',
  ($scope, $location, $routeParams, WorkOrder, Provider, Product, companyPreference, flashService) ->

    $scope.showActivity = true

    $scope.isCancellable = false
    $scope.allowsMultipleProviders = false

    $scope.workOrderProviders = {}
    $scope.workOrderProviderIds = []

    workOrder = WorkOrder.get id: $routeParams.id, ->
      $scope.workOrder = workOrder
      $scope.isCancellable = ['canceled'].indexOf($scope.workOrder.status) == -1
      $scope.showActivity = !$scope.providers
      $scope.allowsMultipleProviders = $scope.workOrder.job || workOrder.work_order_providers.length > 1
      for workOrderProvider in $scope.workOrder.work_order_providers
        $scope.workOrderProviders[workOrderProvider.provider.id] = true
      $scope.workOrder.config.components ||= []

    providers = Provider.query company_id: companyPreference.get(), ->
      $scope.providers = providers
      $scope.showActivity = !$scope.workOrder

    $scope.$watchCollection 'workOrderProviders', ->
      if $scope.workOrderProviders
        $scope.workOrderProviderIds = []
        for id, status of $scope.workOrderProviders
          $scope.workOrderProviderIds.push(id) if status

    $scope.cancelWorkOrder = ->
      $scope.workOrder.status = 'canceled'
      $scope.workOrder.$update().then ->
        flashService.warning('Work order has been cancelled')
        $location.path('/work_orders') unless $scope.workOrder.job_id
        $location.path('/jobs/' + $scope.workOrder.job_id + '/edit') if $scope.workOrder.job_id

    $scope.updateComponents = (e) ->
      i = 0
      for component in $scope.workOrder.config.components
        if component.component == e.target.value
          newValue = e.target.value + String.fromCharCode(e.keyCode)
          $scope.workOrder.config.components[i].component = newValue
          e.target.value = newValue.substring(0, newValue.length - 1)
          break
        i++

    $scope.submit = ->
      lookupWorkOrderProviderIdForProviderId = (providerId) ->
        return null unless providerId
        for wop in $scope.workOrder.work_order_providers
          wopProviderId = if wop.provider then wop.provider.id else wop.provider_id
          return wop.id if wopProviderId == providerId
        null

      workOrderProviders = []
      for providerId in $scope.workOrderProviderIds
        wopId = lookupWorkOrderProviderIdForProviderId(parseInt(providerId))
        workOrderProviders.push({ id: wopId, provider_id: parseInt(providerId) })
      $scope.workOrder.work_order_providers = workOrderProviders

      $scope.workOrder.$update().then ->
        flashService.success('Work order has been updated')
        $location.path('/work_orders') unless $scope.workOrder.job_id
        $location.path('/jobs/' + $scope.workOrder.job_id + '/edit') if $scope.workOrder.job_id

    $scope.$on 'addOrderedProduct', (event, product) ->
      $scope.workOrder.gtins_ordered = []
      $scope.workOrder.items_ordered.push(product)
      for product in $scope.workOrder.items_ordered
        $scope.workOrder.gtins_ordered.push(product.gtin)
      $scope.workOrder.$update().then ->
        flashService.success('Work order has been updated')
]
