module = angular.module('unicornApp.filters', [])

# TODO: I need some unit tests

module.filter 'contactName', ->
  (contactable) ->
    contactable?.name || contactable?.display_name || contactable?.contact?.name

module.filter 'duration', ->
  (duration) ->
    duration = Number(duration)
    hours = Math.floor(duration / 60)
    halves = if 0 <= (duration % 60) < 30 then '0' else '5'
    "#{hours}.#{halves} hours"
