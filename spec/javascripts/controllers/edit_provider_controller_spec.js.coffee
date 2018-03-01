describe 'EditProviderCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('EditProviderCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.value '$location', path: -> undefined
      $provide.value '$routeParams', id: '1234'
      $provide.value 'Provider', get: -> {}
      $provide.value 'flashService', success: -> undefined
      undefined

  describe '$scope.provider', ->

    beforeEach inject (Provider) ->
      spyOn(Provider, 'get').andReturn(@provider = {})
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.provider).toBe(@provider)

    it 'is fetched from the Provider API', inject (Provider, $routeParams) ->
      expect(Provider.get).toHaveBeenCalledWith(id: $routeParams.id)

  describe '$scope.submit()', ->

    beforeEach inject ($q, $scope, Provider) ->
      @deferred = $q.defer()
      @provider = $update: jasmine.createSpy('$update').andReturn(@deferred.promise)
      spyOn(Provider, 'get').andReturn(@provider)
      createController()
      $scope.submit()

    it 'saves provider to server', ->
      expect(@provider.$update).toHaveBeenCalled()

    describe 'when save is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        @deferred.resolve()
        $scope.$digest()

      it 'flashes a success message', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Provider was successfully updated')

      it 'redirects to providers index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/providers')
