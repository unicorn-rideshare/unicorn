describe 'CustomersIndexCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('CustomersIndexCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.factory 'companyPreference', (defaultCompanyId) -> get: -> defaultCompanyId
      $provide.value 'defaultCompanyId', 123
      undefined

  describe '$scope.customers', ->
    beforeEach inject (Customer) ->
      spyOn(Customer, 'paginate').andReturn(@customers = [])
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.customers).toEqual([])

    it 'is fetched from Customer API', inject (Customer, defaultCompanyId) ->
      expect(Customer.paginate).toHaveBeenCalledWith(company_id : 123, page : 1, rpp : 25)
