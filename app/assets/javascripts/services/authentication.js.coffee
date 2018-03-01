module = angular.module('unicornApp.services')

module.factory 'authentication', ['$rootScope', '$base64', '$cookies', '$window', 'User', 'Token', 'preferences',
  ($rootScope, $base64, $cookies, $window, User, Token, preferences) ->

    hasCachedToken: ->
      console.log $cookies.get('x-api-user-id')
      $cookies.get('x-api-user-id') && $cookies.get('x-api-token-id') && $cookies.get('x-api-authorization')

    cacheToken: (token) ->
      hashedToken = $base64.encode(token.token + ':' + token.uuid)

      $cookies.put('x-api-user-id', token.user.id)
      $cookies.put('x-api-token-id', token.id)
      $cookies.put('x-api-authorization', hashedToken)

      fn = -> $window.location.href = '/'
      setTimeout(fn, 10)

    acceptInvitation: (params) ->
      authentication = this
      credentials =
        invitation_token: params.invitation_token
        name: params.name
        email: params.email
        password: params.password
      response = User.save(credentials)
      response.$promise.then ->
        authentication.cacheToken(response.token)

    login: (params) ->
      authentication = this
      credentials =
        email: params.email
        password: params.password
      token = Token.save(credentials)
      token.$promise.then ->
        authentication.cacheToken(token)

    logout: ->
      tokenId = $cookies.get('x-api-token-id')

      destroyCookies = ->
        $cookies.remove('x-api-user-id')
        $cookies.remove('x-api-token-id')
        $cookies.remove('x-api-authorization')

      if tokenId
        Token.delete(id: tokenId).$promise.then ->
          destroyCookies()
          $window.location.href = '/'
        .catch ->
          destroyCookies()
      else
        destroyCookies()
        $window.location.href = '/'

    resetPassword: (params) ->
      requestParams =
        email: params.email
      requestParams.reset_password_token = params.reset_password_token if params.reset_password_token
      requestParams.password = params.password if params.password
      User.reset_password(requestParams)

    signup: (resource, params) ->
      authentication = this
      credentials =
        name: params.name
        email: params.email
        password: params.password
        contact: params.contact
        create_provider: params.createProvider
      response = resource.save(credentials)
      response.$promise.then ->
        authentication.cacheToken(response.token)
]
