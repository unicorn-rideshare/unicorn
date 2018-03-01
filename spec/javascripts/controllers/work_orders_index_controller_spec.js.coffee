describe 'WorkOrdersIndexCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('WorkOrdersIndexCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.factory '$scope', ($rootScope) -> $rootScope.$new()
      $provide.factory 'companyPreference', (defaultCompanyId) -> get: -> defaultCompanyId
      $provide.value 'defaultCompanyId', 123
      undefined

  describe '$scope.collectionClass', ->
    beforeEach inject (WorkOrder) ->
      spyOn(WorkOrder, 'paginate').andReturn(@workOrders = [])
      createController()

    it 'is defined', inject ($scope, WorkOrder) ->
      expect($scope.collectionClass).toEqual(WorkOrder)

  describe '$scope.workOrders', ->
    beforeEach inject (WorkOrder) ->
      spyOn(WorkOrder, 'paginate').andReturn(@workOrders = [])
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.workOrders).toEqual([])

  describe '$scope.query', ->
    beforeEach inject (WorkOrder) ->
      spyOn(WorkOrder, 'paginate').andReturn(@workOrders = [])
      createController()

    it 'it fetches work orders by querying the WorkOrder API', inject ($scope, WorkOrder, defaultCompanyId) ->
      $scope.query()
      expect(WorkOrder.paginate).toHaveBeenCalledWith( company_id : defaultCompanyId, status : 'scheduled', page : 1, rpp : 25 )

  describe '$scope.toggle', ->

    beforeEach ->
      module ($provide) ->
        $provide.value '$event', jasmine.createSpyObj('$event', ['preventDefault', 'stopPropagation'])
        undefined
      createController()

    it 'prevents default on the $event', inject ($scope, $event) ->
      $scope.toggle($event, 'anything')
      expect($event.preventDefault).toHaveBeenCalled()

    it 'stop propagation on the $event', inject ($scope, $event) ->
      $scope.toggle($event, 'anything')
      expect($event.stopPropagation).toHaveBeenCalled()

    it 'closes onOrAfter date picker', inject ($scope, $event) ->
      $scope.toggle($event, 'anything')
      expect($scope.onOrAfterOpened).toBeFalsy()

    it 'closes onOrBefore date picker', inject ($scope, $event) ->
      $scope.toggle($event, 'anything')
      expect($scope.onOrBeforeOpened).toBeFalsy()

    it 'opens the named date picker', inject ($scope, $event) ->
      $scope.toggle($event, 'anything')
      expect($scope['anything']).toBeTruthy()
