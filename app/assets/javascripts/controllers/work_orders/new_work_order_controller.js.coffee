module = angular.module('unicornApp.controllers')

module.controller 'NewWorkOrderCtrl', [
  '$scope', '$routeParams', '$filter', '$location', 'Customer', 'Provider', 'WorkOrder', 'Route', 'Job', 'companyPreference', 'flashService',
  ($scope, $routeParams, $filter, $location, Customer, Provider, WorkOrder, Route, Job, companyPreference, flashService) ->

    $scope.showActivity = false

    $scope.workOrderProviders = {}
    $scope.workOrderProviderIds = []

    $scope.config = { components: [] }

    $scope.$watch 'routeId', (newValue, oldValue) ->
      return unless newValue
      $scope.showActivity = true
      route = Route.get id: $scope.routeId, include_dispatcher_origin_assignment: true, include_provider_origin_assignment: true, ->
        $scope.route = route
        $scope.providers = [$scope.route.provider_origin_assignment.provider]
        $scope.provider = $scope.providers[0]
        $scope.showActivity = !$scope.customers

    $scope.$watch 'jobId', (newValue, oldValue) ->
      return unless newValue
      $scope.showActivity = true
      job = Job.get id: $scope.jobId, ->
        $scope.job = job
        $scope.customers = [$scope.job.customer]
        $scope.customer = $scope.customers[0]
        $scope.showActivity = !$scope.providers

    exp = /routes/i;
    $scope.routeId = if $location.$$path.match(exp) then parseInt($routeParams.id) else null

    exp = /jobs/i;
    $scope.jobId = if $location.$$path.match(exp) then parseInt($routeParams.id) else null

    formatDate = $filter('date')

    $scope.queryResources = ->
      $scope.showActivity = true

      companyId = companyPreference.get()

      unless $scope.jobId
        customers = Customer.query company_id: companyId, ->
          $scope.customers = customers
          $scope.showActivity = !$scope.providers

      unless $scope.routeId
        providers = Provider.query company_id: companyId, ->
          $scope.providers = providers
          $scope.showActivity = !$scope.customers

    $scope.queryAvailability = ->
      if $scope.route || !$scope.customer
        $scope.availabilities = []
        return

      endDate = new Date($scope.startDate.getTime())
      endDate.setDate($scope.startDate.getDate() + 3)
      endDate.setHours(0,0,0,0)

      workOrderProviders = []
      for providerId in $scope.workOrderProviderIds
        workOrderProviders.push({ provider_id: providerId })
      workOrderProviders.push({ provider_id: $scope.provider.id }) if $scope.provider && $scope.provider.id

      workOrderProviderIds = []
      for wop in workOrderProviders
        workOrderProviderIds.push(wop.provider_id)

      $scope.availabilities = if $scope.workOrderParameters.$valid
        Provider.availability(
          company_id: companyPreference.get(),
          customer_id: $scope.customer.id,
          start_date: formatDate($scope.startDate, 'yyyy-MM-dd'),
          end_date: formatDate(endDate, 'yyyy-MM-dd'),
          provider_ids: workOrderProviderIds.join(','),
          estimated_duration: $scope.estimated_duration
        )
      else []

    $scope.startDate = new Date()
    $scope.startDate.setHours(0,0,0,0)

    $scope.$watch 'woParameters.$valid', $scope.queryAvailability
    $scope.$watch 'customer', $scope.queryAvailability
    $scope.$watch 'estimated_duration', $scope.queryAvailability
    $scope.$watch 'startDate', $scope.queryAvailability

    $scope.$watch 'provider', ->
      $scope.workOrderProviders[$scope.provider.id] = true if $scope.provider

    $scope.$watchCollection 'workOrderProviders', ->
      if $scope.workOrderProviders
        $scope.workOrderProviderIds = []
        for id, status of $scope.workOrderProviders
          $scope.workOrderProviderIds.push(id) if status
      $scope.queryAvailability() if $scope.workOrderProviderIds.length > 0

    $scope.updateComponents = (e) ->
      i = 0
      for component in $scope.config.components
        if component.component == e.target.value
          newValue = e.target.value + String.fromCharCode(e.keyCode)
          $scope.config.components[i].component = newValue
          e.target.value = newValue.substring(0, newValue.length - 1)
          break
        i++

    $scope.submit = ->
      preferredScheduledStartDate = if $scope.availabilities.selected then null else (if $scope.route then $scope.route.date else $scope.startDate.toISODateString())

      workOrderProviders = []
      for providerId in $scope.workOrderProviderIds
        workOrderProviders.push({ provider_id: providerId })

      workOrderParams =
        company_id: companyPreference.get()
        customer_id: $scope.customer.id
        config: $scope.config
        description: $scope.description
        work_order_providers: workOrderProviders
        scheduled_start_at: $scope.availabilities.selected
        preferred_scheduled_start_date: preferredScheduledStartDate
        estimated_duration: $scope.estimated_duration
        status: if $scope.availabilities.selected then 'scheduled' else 'awaiting_schedule'
        route_id: $scope.routeId
        job_id: $scope.jobId

      workOrder = WorkOrder.save(workOrderParams)
      workOrder.$promise.then ->
        flashService.success('Work Order created successfully')
        $location.path('/work_orders') unless $scope.routeId || $scope.jobId
        $location.path('/routes/' + $scope.routeId + '/edit') if $scope.routeId
        $location.path('/jobs/' + $scope.jobId + '/wizard') if $scope.jobId

    $scope.valid = ->
      $scope.workOrder.$valid && (($scope.route || $scope.job) || $scope.availabilities?.selected?)

    $scope.queryResources()
]
