describe 'companyPreference', ->

  beforeEach ->
    module('unicornApp.services')

  class MockStorage
    constructor: (@name) ->
      @data = {}
      @keys = []
      @length = 0

    getItem: (key) ->
      @data[key]

    removeItem: (key) ->
      if @data.hasOwnProperty(key)
        @keys.splice @keys.indexOf(key), 1
        delete @data[key]

    setItem: (key, val) ->
      unless @data.hasOwnProperty(key)
        @keys.push(key)
        @length += 1
      @data[key] = String(val)

    key: (i) ->
      @keys[i]

  beforeEach ->
    @$localStorage = new MockStorage('localStorage')
    @$sessionStorage = new MockStorage('sessionStorage')
    @$rootScope = jasmine.createSpyObj('$rootScope', ['$broadcast'])
    @defaultCompanyId = 9999

    module ($provide) =>
      $provide.value '$window', {}
      $provide.value '$location', jasmine.createSpyObj('$location', ['url'])
      $provide.value '$localStorage', @$localStorage
      $provide.value '$sessionStorage', @$sessionStorage
      $provide.value '$rootScope', @$rootScope
      $provide.value 'defaultCompanyId', @defaultCompanyId
      undefined

  describe '#get', ->

    describe 'when no prior value is known', ->

      it 'returns defaultCompanyId', inject (companyPreference) ->
        expect(companyPreference.get()).toEqual(9999)

      describe 'when defaultCompanyId is null', ->

        beforeEach ->
          spyOn(@$sessionStorage, 'setItem').andCallThrough()
          spyOn(@$localStorage, 'setItem').andCallThrough()
          module ($provide) ->
            $provide.value 'defaultCompanyId', null
            undefined

        it 'returns null', inject (companyPreference) ->
          expect(companyPreference.get()).toEqual(null)

        it 'does not write the null value to storage', inject (companyPreference) ->
          companyPreference.get()
          expect(@$sessionStorage.setItem).not.toHaveBeenCalled()
          expect(@$localStorage.setItem).not.toHaveBeenCalled()

    describe 'when a value was set in a previous session', ->

      beforeEach ->
        @$localStorage.setItem('currentCompanyId', 1234)

      it 'returns value from localStorage', inject (companyPreference) ->
        expect(companyPreference.get()).toEqual(1234)

    describe 'when a value was set in the current session', ->

      beforeEach ->
        @$localStorage.setItem('currentCompanyId', 1234)
        @$sessionStorage.setItem('currentCompanyId', 4321)

      it 'returns value from sessionStorage', inject (companyPreference) ->
        expect(companyPreference.get()).toEqual(4321)

  describe '#set', ->

    beforeEach ->
      spyOn(@$sessionStorage, 'setItem').andCallThrough()
      spyOn(@$localStorage, 'setItem').andCallThrough()

    it 'returns the new value', inject (companyPreference) ->
      value = companyPreference.set(2222)
      expect(value).toEqual(2222)

    describe 'when current value does not equal new value', ->

      beforeEach inject (companyPreference, $location) ->
        @$localStorage.setItem('currentCompanyId', 1111)
        companyPreference.set(2222)

      it 'writes new value to session storage', ->
        expect(@$sessionStorage.setItem).toHaveBeenCalledWith('currentCompanyId', 2222)

      it 'writes new value to local storage', ->
        expect(@$localStorage.setItem).toHaveBeenCalledWith('currentCompanyId', 2222)

      it 'triggers an event on $rootScope', ->
        expect(@$rootScope.$broadcast).toHaveBeenCalledWith('currentCompanyIdChanged', 2222, 1111)

      it 'forces navigation to the dashboard', inject ($location) ->
        expect($location.url).toHaveBeenCalledWith('/')

    describe 'when current value equals new value', ->

      beforeEach inject (companyPreference) ->
        @$localStorage.setItem('currentCompanyId', 1111)
        companyPreference.set(1111)

      it 'does not trigger an event on $rootScope', ->
        expect(@$rootScope.$broadcast).not.toHaveBeenCalled()

  describe '#clear', ->

    beforeEach inject (companyPreference) ->
      spyOn(@$sessionStorage, 'removeItem').andCallThrough()
      spyOn(@$localStorage, 'removeItem').andCallThrough()
      companyPreference.clear()

    it 'removes preferences from the session storage', ->
      expect(@$sessionStorage.removeItem).toHaveBeenCalledWith('currentCompanyId')

    it 'removes preferences from the localStorage storage', ->
      expect(@$sessionStorage.removeItem).toHaveBeenCalledWith('currentCompanyId')

  describe '^beforeunload', ->

    beforeEach inject (companyPreference) ->
      spyOn(@$localStorage, 'setItem').andCallThrough()
      @$sessionStorage.setItem('currentCompanyId', 1234)
      companyPreference.get() # requires a read or write to prime write-back pump

    it 'writes current value back to local storage', inject ($window) ->
      angular.element($window).trigger('beforeunload')
      expect(@$localStorage.setItem).toHaveBeenCalledWith('currentCompanyId', 1234)

    describe 'when company preference is undefined', ->

      beforeEach inject (companyPreference) ->
        companyPreference.clear()

      it 'does not write to storage', inject ($window) ->
        angular.element($window).trigger('beforeunload')
        expect(@$localStorage.setItem).not.toHaveBeenCalled()
