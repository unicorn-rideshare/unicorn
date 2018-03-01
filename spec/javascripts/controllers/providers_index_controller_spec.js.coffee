describe 'ProvidersIndexCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('ProvidersIndexCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.factory 'companyPreference', (defaultCompanyId) -> get: -> defaultCompanyId
      $provide.value 'defaultCompanyId', 123
      undefined

  describe '$scope.collectionClass', ->
    beforeEach inject (Provider) ->
      spyOn(Provider, 'paginate').andReturn(@providers = [])
      createController()

    it 'is defined', inject ($scope, Provider) ->
      expect($scope.collectionClass).toEqual(Provider)

  describe '$scope.providers', ->
    beforeEach inject (Provider) ->
      spyOn(Provider, 'paginate').andReturn(@providers = [])
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.providers).toEqual([])

    it 'it fetched from Provider API', inject (Provider, defaultCompanyId) ->
      expect(Provider.paginate).toHaveBeenCalledWith({ company_id : defaultCompanyId, page : 1, rpp : 25 })
