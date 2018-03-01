describe 'EditWorkOrderCtrl', ->

  createController = ->
    inject ($controller) ->
      $controller('EditWorkOrderCtrl')

  beforeEach ->
    module 'unicornApp.controllers'
    module ($provide) ->
      $provide.factory '$scope', ($rootScope) -> $rootScope.$new()
      $provide.value '$routeParams', id: '123'
      $provide.factory 'flashService', ->
        danger: -> undefined
        success: -> undefined
        warning: -> undefined
      $provide.factory 'WorkOrder', ($q) ->
        get: ->
          $delete: -> $q.defer().promise
          $update: -> $q.defer().promise
      undefined

  describe '$scope.workOrder', ->

    beforeEach inject (WorkOrder) ->
      spyOn(WorkOrder, 'get').andReturn(@workOrder = {})
      createController()

    it 'is defined', inject ($scope) ->
      expect($scope.workOrder).toBe(@workOrder)

    it 'is fetched from WorkOrder API', inject (WorkOrder, $routeParams) ->
      expect(WorkOrder.get).toHaveBeenCalledWith($routeParams, jasmine.any(Function))

  describe '$scope.cancelWorkOrder()', ->

    beforeEach inject (WorkOrder, $q) ->
      @deferred = $q.defer()
      workOrder = $update: jasmine.createSpy('$update').andReturn(@deferred.promise)
      spyOn(WorkOrder, 'get').andReturn(workOrder)

    beforeEach inject ($scope) ->
      createController()
      $scope.cancelWorkOrder()

    it 'cancels the work order', inject ($scope) ->
      expect($scope.workOrder.$update).toHaveBeenCalled()

    describe 'when cancellation is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'warning')
        @deferred.resolve()
        $scope.$digest()

      it 'informs user of success', inject (flashService) ->
        expect(flashService.warning).toHaveBeenCalledWith('Work order has been cancelled')

      it 'redirects to the work orders index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/work_orders')

    describe 'when cancellation fails', ->
      beforeEach inject ($scope, flashService) ->
        spyOn(flashService, 'danger')
        @deferred.reject()
        $scope.$digest()

      it 'alerts user to an error', inject (flashService) ->
        expect(flashService.danger).toHaveBeenCalledWith('Sorry, but an error has occurred')

  describe '$scope.submit()', ->

    beforeEach inject (WorkOrder, $q) ->
      @deferred = $q.defer()
      workOrder = $update: jasmine.createSpy('$update').andReturn(@deferred.promise)
      spyOn(WorkOrder, 'get').andReturn(workOrder)

    beforeEach inject ($scope) ->
      createController()
      $scope.submit()

    it 'saves the work order to the API', inject ($scope) ->
      expect($scope.workOrder.$update).toHaveBeenCalled()

    describe 'when save is successful', ->
      beforeEach inject ($scope, $location, flashService) ->
        spyOn($location, 'path')
        spyOn(flashService, 'success')
        @deferred.resolve()
        $scope.$digest()

      it 'informs user of success', inject (flashService) ->
        expect(flashService.success).toHaveBeenCalledWith('Work order has been updated')

      it 'redirects to the work orders index', inject ($location) ->
        expect($location.path).toHaveBeenCalledWith('/work_orders')

    describe 'when save is unsuccessful', ->
      beforeEach inject ($scope, flashService) ->
        spyOn(flashService, 'danger')
        @deferred.reject()
        $scope.$digest()

      it 'alerts user to an error', inject (flashService) ->
        expect(flashService.danger).toHaveBeenCalledWith('Sorry, but an error has occurred')
