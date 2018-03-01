describe 'NewWorkOrderCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('NewWorkOrderCtrl')

  beforeEach ->
    module('unicornApp.controllers')
    module ($provide) ->
      $provide.factory 'companyPreference', (defaultCompanyId) -> get: -> defaultCompanyId
      $provide.factory 'flashService', -> success: -> undefined
      $provide.factory 'Customer', -> query: -> []
      $provide.factory 'Provider', -> query: -> []
      $provide.factory 'WorkOrder', ($q) ->
        availability: -> []
        save: -> $promise: $q.defer().promise
      undefined

  beforeEach ->
    # Don't follow my lead here... faking the date like this is an awful pattern
    @RealDate = RealDate = Date
    spyOn(window, 'Date').andCallFake -> new RealDate(2014, 9, 30)

  describe '$scope.customers', ->

    beforeEach inject (Customer, companyPreference) ->
      spyOn(Customer, 'query').andReturn(@customers = [])
      spyOn(companyPreference, 'get').andReturn(789)
      createController()

    it 'queries the Customer API', inject (Customer) ->
      expect(Customer.query).toHaveBeenCalledWith(company_id: 789)

    it 'is defined', inject ($scope) ->
      expect($scope.customers).toBe(@customers)

  describe '$scope.providers', ->

    beforeEach inject (Provider, companyPreference) ->
      spyOn(Provider, 'query').andReturn(@providers = [])
      spyOn(companyPreference, 'get').andReturn(789)
      createController()

    it 'queries the Provider API', inject (Provider) ->
      expect(Provider.query).toHaveBeenCalledWith(company_id: 789)

    it 'is defined', inject ($scope) ->
      expect($scope.providers).toBe(@providers)

  describe '$scope.today', ->

    beforeEach ->
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.today).toEqual(jasmine.any(@RealDate))

  describe '$scope.startDate', ->

    beforeEach ->
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.startDate).toEqual(jasmine.any(@RealDate))

    it 'is set to midnight', inject ($scope) ->
      midnightToday = new @RealDate(2014, 9, 30, 0, 0, 0, 0)
      expect($scope.startDate).toEqual(midnightToday)

  describe '$scope.submit()', ->
    beforeEach inject ($q, companyPreference, $scope, WorkOrder) ->
      @deferred = $q.defer()

      spyOn(companyPreference, 'get').andReturn(123)
      spyOn(WorkOrder, 'save').andReturn($promise: @deferred.promise)

      $scope.workOrderParameters = $valid: true
      $scope.customer = id: 456, contact: { time_zone_id: 'Eastern Time (US & Canada)' }
      $scope.provider = id: 789
      $scope.startDate = new @RealDate(2014, 9, 30)
      $scope.description = 'do some work'
      $scope.estimated_duration = '60'
      $scope.availabilities = selected: '2014-10-30T14:00:00-0400'

      createController()
      $scope.submit()

    it 'posts work order to the server', inject ($scope, WorkOrder) ->
      expect(WorkOrder.save).toHaveBeenCalledWith(
        company_id: 123,
        customer_id: 456,
        description: 'do some work',
        work_order_providers: [ provider_id: 789 ],
        scheduled_start_at: '2014-10-30T14:00:00-0400',
        preferred_scheduled_start_date: null,
        estimated_duration: $scope.estimated_duration,
        status: 'scheduled'
      )

    describe 'when work order is successfully created', ->

      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        @deferred.resolve()
        $scope.$digest()

      it 'flashes a success message', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Work Order created successfully')

      it 'redirects to work orders index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/work_orders')

  describe '$scope.valid()', ->

    describe 'when form is invalid', ->
      beforeEach inject ($scope) ->
        $scope.workOrder = $valid: false
        createController()

      it 'returns false', inject ($scope) ->
        expect($scope.valid()).toBeFalsy()

    describe 'when form is valid', ->
      beforeEach inject ($scope) ->
        $scope.workOrder = $valid: true

      describe 'and no availability is selected', ->
        beforeEach inject ($scope) ->
          $scope.availabilities = {}
          createController()

        it 'returns false', inject ($scope) ->
          expect($scope.valid()).toBeFalsy()

      describe 'and availability is selected', ->
        beforeEach inject ($scope) ->
          $scope.availabilities = selected: '2014-07-22T02:00:00-0400'
          createController()

        it 'returns true', inject ($scope) ->
          expect($scope.valid()).toBeTruthy()

  describe 'when work order parameters are valid', ->
    beforeEach inject ($scope, WorkOrder, companyPreference) ->
      spyOn(WorkOrder, 'availability').andReturn(@availability = [])
      spyOn(companyPreference, 'get').andReturn(678)
      createController()
      $scope.customer = id: 1234
      $scope.provider = id: 2345
      $scope.estimated_duration = 60
      $scope.workOrderParameters = $valid: true
      $scope.$digest()

    it 'queries for availability', inject (WorkOrder) ->
      expect(WorkOrder.availability).toHaveBeenCalledWith(
        company_id: 678,
        customer_id: 1234,
        start_date: '2014-10-30',
        end_date: '2014-11-02',
        estimated_duration: 60,
        work_order_providers: [ provider_id: 2345 ]
      )

    it 'assigns availability to the $scope', inject ($scope) ->
      expect($scope.availabilities).toEqual(@availability)

    describe 'when selected customer changes', ->
      beforeEach inject ($scope) ->
        $scope.customer = id: 5678
        $scope.$digest()

      it 're-queries for availability', inject (WorkOrder) ->
        expect(WorkOrder.availability).toHaveBeenCalledWith(
          company_id: 678,
          customer_id: 5678,
          start_date: '2014-10-30',
          end_date: '2014-11-02',
          estimated_duration: 60,
          work_order_providers: [ provider_id: 2345 ]
        )

    describe 'when selected estimated duration changes', ->
      beforeEach inject ($scope) ->
        $scope.estimated_duration = 90
        $scope.$digest()

      it 're-queries for availability', inject (WorkOrder) ->
        expect(WorkOrder.availability).toHaveBeenCalledWith(
          company_id: 678,
          customer_id: 1234,
          start_date: '2014-10-30',
          end_date: '2014-11-02',
          estimated_duration: 90,
          work_order_providers: [ provider_id: 2345 ]
        )

    describe 'when start date changes', ->
      beforeEach inject ($scope) ->
        window.Date = @RealDate
        $scope.startDate = new @RealDate(2014, 10, 2)
        $scope.$digest()

      it 're-queries for availability', inject (WorkOrder) ->
        expect(WorkOrder.availability).toHaveBeenCalledWith(
          company_id: 678,
          customer_id: 1234,
          start_date: '2014-11-02',
          end_date: '2014-11-05',
          estimated_duration: 60,
          work_order_providers: [ provider_id: 2345 ]
        )

  describe 'when work order parameters are invalid', ->
    beforeEach inject (WorkOrder, $scope) ->
      spyOn(WorkOrder, 'availability')
      $scope.workOrderParameters = $valid: false
      createController()
      $scope.$digest()

    it 'does not query for availability', inject (WorkOrder) ->
      expect(WorkOrder.availability).not.toHaveBeenCalled()

    it 'assigns an empty array to $scope', inject ($scope) ->
      expect($scope.availabilities).toEqual([])
