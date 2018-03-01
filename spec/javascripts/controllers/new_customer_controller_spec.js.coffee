describe 'NewCustomerCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('NewCustomerCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.value '$location', path: -> undefined
      $provide.value 'Customer', jasmine.createSpy('Customer')
      $provide.value 'flashService', success: -> undefined
      $provide.value 'companyPreference', get: -> 12345
      undefined

  describe '$scope.customer', ->

    beforeEach inject (Customer) ->
      Customer.andReturn(@customer = {})
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.customer).toBe(@customer)

    it 'is a new instance of Customer resource', inject (Customer) ->
      expect(Customer).toHaveBeenCalledWith(company_id: 12345)

  describe '$scope.submit()', ->

    beforeEach inject ($q, $scope, Customer) ->
      @deferred = $q.defer()
      @customer = $save: jasmine.createSpy('$save').andReturn(@deferred.promise)
      Customer.andReturn(@customer)
      createController()
      $scope.submit()

    it 'saves customer to server', ->
      expect(@customer.$save).toHaveBeenCalled()

    describe 'when save is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        $scope.submit()
        @deferred.resolve()
        $scope.$digest()

      it 'flashes a success message', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Customer was successfully created')

      it 'redirects to customers index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/customers')
