describe 'EditCompanyModalCtrl', ->

  beforeEach ->
    module('unicornApp.controllers')

  beforeEach inject ($rootScope, $q) ->
    @$scope = $rootScope
    @$modalInstance = jasmine.createSpyObj('$modalInstance', ['close', 'dismiss'])
    @deferred = $q.defer()

    @company = jasmine.createSpyObj('company', ['$update', '$save'])
    @company.contact = {}
    @company.$update.andReturn(@deferred.promise)
    @company.$save.andReturn(@deferred.promise)

  beforeEach inject ($controller) ->
    $controller 'EditCompanyModalCtrl',
      $scope: @$scope,
      $modalInstance: @$modalInstance,
      company: @company

  it 'adds company to $scope', ->
    expect(@$scope.company).toEqual(@company)
    expect(@$scope.contact).toEqual(@company.contact)

  describe '$scope.save(company)', ->
    beforeEach ->
      @company.name = 'Nick'
      @$scope.save(@company)

    describe 'when company is new', ->
      beforeEach ->
        @company.id = undefined
        @$scope.save(@company)

      it 'creates the company', ->
        expect(@company.$save).toHaveBeenCalled()

    describe 'when company exists', ->
      beforeEach ->
        @company.id = 12345
        @$scope.save(@company)

      it 'updates the company', ->
        expect(@company.$update).toHaveBeenCalled()

    describe 'when save is successful', ->

      beforeEach ->
        @$scope.save(@company)
        @$scope.$apply => @deferred.resolve({})

      it 'closes the modal', ->
        expect(@$modalInstance.close).toHaveBeenCalled()

    describe 'when save is unsuccessful', ->

      beforeEach ->
        @$scope.save(@company)
        @$scope.$apply => @deferred.reject()

      it 'does not close the modal', ->
        expect(@$modalInstance.close).not.toHaveBeenCalled()

  describe '$scope.cancel()', ->

    beforeEach ->
      @$scope.cancel()

    it 'dismisses the modal', ->
      expect(@$modalInstance.dismiss).toHaveBeenCalled()
