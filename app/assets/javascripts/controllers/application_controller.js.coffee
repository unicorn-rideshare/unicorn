module = angular.module('unicornApp.controllers')

module.controller 'ApplicationCtrl', ['$window', '$scope', '$location', 'User', 'preferences', 'websocket', 'userId',
  ($window, $scope, $location, User, preferences, websocket, userId) ->

    $scope.conversationElements = {}

    if userId
      currentUser = User.get id: userId, ->
        $scope.currentUser = currentUser
        $scope.currentUserIsAdmin = false
        $scope.currentUserIsCompanyAdmin = $scope.currentUser && $scope.currentUser.company_ids && $scope.currentUser.company_ids.count > 0
        $scope.currentUserIsProvider = $scope.currentUser && $scope.currentUser.provider_ids && $scope.currentUser.provider_ids.count > 0

    $scope.$on '$routeChangeSuccess', ->
      $window.scrollTo(0, 0)
      $scope.setActiveNavigationItem()

      $scope.bindWebsocket() if websocket

    $scope.bindWebsocket = ->
      websocket.unbindContext()
      channel = 'user_' + preferences.get('x-api-user-id')
      onNotificationReceived = (notification) ->
        message = notification.message
        payload = notification.payload
        $scope.$parent.$broadcast(message, payload) if message
      websocket.bind(channel, 'push', onNotificationReceived)

    $scope.$on 'loadConversation', (event, params) ->
      userId = preferences.get('x-api-user-id')
      qualifier = if userId > params.userId then (params.userId + '_' + userId) else (userId + '_' + params.userId)
      $scope.$broadcast('startConversation', params)
      $scope.$broadcast('loadConversation' + qualifier, qualifier.replace('_', '|'))

    $scope.setActiveNavigationItem = ->
      angular.element('ul.nav.navbar-nav li').removeClass('active')
      angular.element('ul.nav.navbar-nav li a[href^="#' + $location.path().replace('/', '').split('/')[0] + '"]').parent('li').addClass('active')
]
