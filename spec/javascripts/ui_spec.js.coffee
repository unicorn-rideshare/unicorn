describe 'ui.provide', ->

  beforeEach ->
    module('ui.provide')
    module ($provide) ->
      $provide.value 'flash', []
      undefined

  describe 'flashService', ->

    describe '#all()', ->
      it 'returns an array of messages', inject (flash, flashService) ->
        expect(flashService.all()).toEqual(flash)

    describe '#success(message)', ->

      it 'adds a "success" message', inject (flash, flashService) ->
        flashService.success('things are good')
        expect(flash).toContain(type: 'success', message: 'things are good')

    describe '#danger(message)', ->

      it 'adds a "danger" message', inject (flash, flashService) ->
        flashService.danger('things are bad')
        expect(flash).toContain(type: 'danger', message: 'things are bad')

    describe '#dismiss(danger)', ->

      beforeEach inject (flash) ->
        @message = type: 'test', message: 'this is a test'
        flash.push @message

      it 'removes messages from the array', inject (flash, flashService) ->
        flashService.dismiss(@message)
        expect(flash).not.toContain(@message)

    describe '#info(message)', ->

      it 'adds a "info" message', inject (flash, flashService) ->
        flashService.info('things are')
        expect(flash).toContain(type: 'info', message: 'things are')

    describe '#warning(message)', ->

      it 'adds a "warning" message', inject (flash, flashService) ->
        flashService.warning('things are!')
        expect(flash).toContain(type: 'warning', message: 'things are!')

  describe 'flashMessages', ->

    beforeEach inject ($compile, $rootScope, flash) ->
      flash.push @warning = type: 'warning', message: 'warning message'
      flash.push @info = type: 'info', message: 'info message'
      @subject = $compile('<flash-messages></flash-messages>')($rootScope)
      $rootScope.$digest()

    it 'renders an alert for each flash message', ->
      expect(@subject.find('.alert').length).toEqual(2)

    it 'renders a warning message', ->
      expect(@subject).toContain('.alert-warning:contains("warning message")')

    it 'renders a info message', ->
      expect(@subject).toContain('.alert-info:contains("info message")')

    describe 'scope.dismiss(danger)', ->

      beforeEach inject (flashService) ->
        spyOn(flashService, 'dismiss').andCallThrough()
        @subject.find('.alert-warning .close').click()

      it 'dismisses messages through flashService', inject (flashService) ->
        expect(flashService.dismiss).toHaveBeenCalledWith(@warning)

      it 'removes dismissed dangers from DOM', ->
        expect(@subject).not.toContain('.danger-warning')
