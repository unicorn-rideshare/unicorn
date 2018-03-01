module = angular.module('unicornApp.services')

module.factory 'facebook', ['$window', 'baseUrl', 'facebookAppId',
  ($window, baseUrl, facebookAppId) ->

    $window.fbAsyncInit = ->
      $window.FB.init
        appId: facebookAppId
        xfbml: true
        version: 'v2.4'

    fbUser: null

    refreshLoginStatus: (onConnected, onDisconnected) ->
      self = @
      $window.FB.getLoginStatus (response) ->
        self.fbUserConnected(response, onConnected) if response.status == 'connected'
        self.fbUserDisconnected(response, onDisconnected) if response.status != 'connected'

    fbUserConnected: (response, onConnected) ->
      accessToken = response.authResponse.accessToken
      userId = response.authResponse.userID
      signedRequest = response.authResponse.signedRequest

      self = @

      $window.FB.api('/me', { fields: 'id,name,email,picture' }, (response) ->
        self.fbUser = response
        onConnected(self.fbUser)
      )

    fbUserDisconnected: (response, onDisconnected) ->
      onDisconnected(@fbUser)
      @fbUser = null

    openShareDialog: ->
      params =
        method: 'share'
        href: baseUrl

      callback = (response) ->
        console.log response

      $window.FB.ui(params, callback)
]
