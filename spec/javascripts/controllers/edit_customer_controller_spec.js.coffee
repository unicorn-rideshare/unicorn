describe 'EditCustomerCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('EditCustomerCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.value '$location', path: -> undefined
      $provide.value '$routeParams', id: '1234'
      $provide.value 'Customer', get: -> {}
      $provide.value 'flashService', success: -> undefined
      undefined

  describe '$scope.customer', ->

    beforeEach inject (Customer) ->
      spyOn(Customer, 'get').andReturn(@customer = {})
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.customer).toBe(@customer)

    it 'is fetched from the Customer API', inject (Customer, $routeParams) ->
      expect(Customer.get).toHaveBeenCalledWith(id: $routeParams.id)

  describe '$scope.submit()', ->

    beforeEach inject ($q, $scope, Customer) ->
      @deferred = $q.defer()
      @customer = $update: jasmine.createSpy('$update').andReturn(@deferred.promise)
      spyOn(Customer, 'get').andReturn(@customer)
      createController()
      $scope.submit()

    it 'saves customer to server', ->
      expect(@customer.$update).toHaveBeenCalled()

    describe 'when save is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        @deferred.resolve()
        $scope.$digest()

      it 'flashes a success message', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Customer was successfully updated')

      it 'redirects to customers index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/customers')
