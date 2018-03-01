module = angular.module('unicornApp.services')

# DEPRECATED! (this will get migrated into the preferences service in the near future)

module.factory 'companyPreference', ['$window', '$rootScope', '$location', '$cookies', 'defaultCompanyId',
  ($window, $rootScope, $location, $cookies, defaultCompanyId) ->
    clear: ->
      delete $cookies.remove('x-api-company-id')
      delete $cookies.remove('x-shown-create-company-prompt')

    get: ->
      $cookies.get('x-api-company-id') || defaultCompanyId

    set: (companyId) ->
      oldValue = @get()
      unless companyId == oldValue
        currentValue = companyId
        $cookies['x-api-company-id'] = companyId
        $rootScope.$broadcast('currentCompanyIdChanged', currentValue, oldValue)
        $location.url('/')
      currentValue

    hasPromptedUser: ->
      return true if $cookies.get('x-shown-create-company-prompt')
      $cookies.put('x-shown-create-company-prompt', true)
      false
]
