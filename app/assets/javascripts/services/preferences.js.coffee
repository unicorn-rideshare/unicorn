module = angular.module('unicornApp.services')

module.factory 'preferences', ['$cookies', '$window', '$rootScope',
  ($cookies, $window, $rootScope) ->

    delete: (key) ->
      $cookies.remove(key)

    get: (key) ->
      $cookies.get(key)

    set: (key, value) ->
      oldValue = @get(key)
      unless value == oldValue
        $cookies.put(key, value)
        $rootScope.$broadcast(key + 'Changed', value, oldValue)
      value
]
