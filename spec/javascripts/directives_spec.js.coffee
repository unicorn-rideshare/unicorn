describe 'unicornApp.directives', ->

  beforeEach ->
    module('unicornApp.directives')

  describe 'usStateSelect', ->

    beforeEach ->
      module ($provide) ->
        $provide.value('USStates', [{ value: 'AB', display: 'First Option' }, { value: 'CD', display: 'Second Option' }])
        undefined

    beforeEach inject ($compile, $rootScope) ->
      $rootScope.state = 'CD'
      @subject = $compile('<us-state-select ng-model="state" placeholder="--choose--"></us-state-select>')($rootScope)
      $rootScope.$digest()

    it 'renders a select box', ->
      expect(@subject).toBeMatchedBy('select')

    it 'renders a list of options for each state', ->
      # TODO: Find a better way to inspect the select box... hate the value="index" check
      expect(@subject).toContain('option[value="0"]:contains("First Option")')
      expect(@subject).toContain('option[value="1"]:contains("Second Option")')

    it 'renders a placeholder choice', ->
      expect(@subject).toContain('option:contains("--choose--")')

    it 'has a default value for placeholder', inject ($compile, $rootScope) ->
      elem = $compile('<us-state-select></us-state-select>')($rootScope)
      $rootScope.$digest()
      expect(elem).toContain('option:contains("--")')
