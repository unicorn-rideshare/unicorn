describe 'AccountMenuCtrl', ->

  beforeEach ->
    module('unicornApp.controllers')

  beforeEach inject ($rootScope, $q) ->
    @$scope = $rootScope
    @deferred = $q.defer()

    @company = { id: 1234, contact: {}, $get: jasmine.createSpy('company.$get') }
    @newCompany = { contact: {} }
    @companies = [ @company ]

    @Company = jasmine.createSpy('Company').andReturn(@newCompany)
    @Company.query = jasmine.createSpy('Company.query').andReturn(@companies)

    @$modal = jasmine.createSpyObj('$modal', ['open'])
    @$modal.open.andReturn(result: @deferred.promise)

    @authentication = jasmine.createSpyObj('authentication', ['logout'])

    @$window = { location: { href: '' } }

    @companyPreference = jasmine.createSpyObj('companyPreference', ['clear', 'get', 'set'])

  beforeEach inject ($controller) ->
    $controller 'AccountMenuCtrl',
      $scope: @$scope,
      Company: @Company,
      $modal: @$modal,
      $user: @$user,
      $window: @$window,
      authentication: @authentication
      companyPreference: @companyPreference

  it 'adds companies to the $scope', ->
    expect(@$scope.companies).toEqual(@companies)

  it 'adds accountMenuOpen to the $scope', ->
    expect(@$scope.accountMenuOpen).toBe(false)

  describe '$scope.currentCompany', ->
    beforeEach ->
      @companies.length = 0

    describe 'when companies is empty', ->
      beforeEach ->
        @$scope.$digest()

      it 'is undefined', ->
        expect(@$scope.currentCompany).toBeUndefined()

    describe 'when companies has values', ->
      beforeEach ->
        @companies.push { id: 123 }, { id: 456 }, { id: 789 }
        @$scope.$digest()

      it 'equals the first company', ->
        expect(@$scope.currentCompany).toEqual(id: 123)

    describe 'when user has selected a company', ->
      beforeEach ->
        @companies.push { id: 123 }, { id: 456 }, { id: 789 }
        @companyPreference.get.andReturn(456)
        @$scope.$digest()

      it 'equals the selected company', ->
        expect(@$scope.currentCompany).toEqual(id: 456)

  describe '$scope^currentCompanyIdChanged', ->

    beforeEach ->
      @company1 = id: 111
      @company2 = id: 222
      @companies.length = 0
      @companies.push @company1, @company2
      @$scope.$digest()
      @$scope.$broadcast 'currentCompanyIdChanged', 222, 111

    it 'updates $scope.currentCompany', ->
      expect(@$scope.currentCompany).toEqual(@company2)

  describe '$scope.newCompany()', ->

    beforeEach ->
      @$scope.accountMenuOpen = true
      @$scope.newCompany()

    it 'closes the account menu', ->
      expect(@$scope.accountMenuOpen).toBe(false)

    it 'opens the modal', ->
      modalArgs = jasmine.objectContaining
        controller: 'EditCompanyModalCtrl',
      expect(@$modal.open).toHaveBeenCalledWith(modalArgs)

    describe 'when modal is closed', ->

      beforeEach ->
        @newCompanyId = 5555
        @$scope.$apply =>
          @newCompany.id = @newCompanyId
          @deferred.resolve()

      it 'adds the new company into the company list', ->
        expect(@companies).toContain(@newCompany)

      it 'sets the new company as the preferred company', ->
        expect(@companyPreference.set).toHaveBeenCalledWith(@newCompanyId)

  describe '$scope.editCompany()', ->

    beforeEach ->
      @$scope.accountMenuOpen = true
      @$scope.editCompany(@company)

    it 'closes the account menu', ->
      expect(@$scope.accountMenuOpen).toBe(false)

    it 'opens the modal', ->
      modalArgs = jasmine.objectContaining
        controller: 'EditCompanyModalCtrl',
      expect(@$modal.open).toHaveBeenCalledWith(modalArgs)

    describe 'when modal is dismissed', ->

      beforeEach ->
        @$scope.$apply => @deferred.reject()

      it 'reloads company details from server', ->
        expect(@company.$get).toHaveBeenCalled()

  describe '$scope.selectableCompany(company)', ->
    beforeEach ->
      @company1 = id: 1234
      @company2 = id: 4321
      @$scope.currentCompany = @company1

    describe 'when company is currentCompany', ->

      it 'returns false', ->
        expect(@$scope.selectableCompany(@company1)).toBe(false)

    describe 'when company is not currentCompany', ->

      it 'returns true', ->
        expect(@$scope.selectableCompany(@company2)).toBe(true)

  describe '$scope.selectCompany(company)', ->

    beforeEach ->
      @newCompany = { id: 1234 }
      @$scope.accountMenuOpen = true
      @$scope.selectCompany(@newCompany)

    it 'updates the currentPreference service', ->
      expect(@companyPreference.set).toHaveBeenCalledWith(1234)

    it 'closes the account menu', ->
      expect(@$scope.accountMenuOpen).toBe(false)

  describe '$scope.logout()', ->
    beforeEach ->
      @$scope.logout()

    it 'logs out the current user', ->
      expect(@authentication.logout).toHaveBeenCalled()
