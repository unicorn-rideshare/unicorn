describe 'NewProviderCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('NewProviderCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.value '$location', path: -> undefined
      $provide.value 'Provider', jasmine.createSpy('Provider')
      $provide.value 'flashService', success: -> undefined
      $provide.value 'companyPreference', get: -> 12345
      undefined

  describe '$scope.provider', ->

    beforeEach inject (Provider) ->
      Provider.andReturn(@provider = {})
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.provider).toBe(@provider)

    it 'is a new instance of Provider resource', inject (Provider) ->
      expect(Provider).toHaveBeenCalledWith(company_id: 12345)

  describe '$scope.submit()', ->

    beforeEach inject ($q, $scope, Provider) ->
      @deferred = $q.defer()
      @provider = $save: jasmine.createSpy('$save').andReturn(@deferred.promise)
      Provider.andReturn(@provider)
      createController()
      $scope.submit()

    it 'saves provider to server', ->
      expect(@provider.$save).toHaveBeenCalled()

    describe 'when save is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        $scope.submit()
        @deferred.resolve()
        $scope.$digest()

      it 'flashes a success message', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Provider was successfully created')

      it 'redirects to providers index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/providers')
