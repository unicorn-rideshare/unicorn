describe 'unicornApp.values', ->

  beforeEach ->
    module('unicornApp.values')

  describe 'USStates', ->

    beforeEach inject (USStates) ->
      @states = USStates

    it 'returns an array of states', ->
      expect(@states).toEqual jasmine.any(Array)

    it 'uses abbreviations for values', ->
      expect(state.value).toMatch /^[A-Z]{2}$/ for state in @states
