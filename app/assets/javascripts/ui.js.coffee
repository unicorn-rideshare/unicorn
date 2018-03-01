module = angular.module('ui.provide', [])

# ERB template can override this to pre-load the flash
module.value 'flash', []

module.factory 'flashService', ['flash',
  (flash) ->
    all: -> flash

    clear: ->
      self = this
      for alert in flash
        self.dismiss(alert)

    danger: (message) ->
      flash.push(type: 'danger', message: message)

    dismiss: (alert) ->
      for _alert, i in flash
        flash.splice(i, 1) if _alert is alert

    info: (message) ->
      flash.push(type: 'info', message: message)

    success: (message) ->
      flash.push(type: 'success', message: message)

    warning: (message) ->
      flash.push(type: 'warning', message: message)
]

module.directive 'flashMessages', ['flashService',
  (flashService) ->
    restrict: 'AE',
    scope: true,
    template: '<alert ng-repeat="alert in alerts" type="{{ alert.type }}" close="dismiss(alert)">{{ alert.message }}</alert>',
    link: (scope) ->
      scope.alerts = flashService.all()
      scope.dismiss = (alert) ->
        flashService.dismiss(alert)
]
