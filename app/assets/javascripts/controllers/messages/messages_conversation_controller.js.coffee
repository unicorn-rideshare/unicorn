module = angular.module('unicornApp.controllers')

module.controller 'MessagesConversationCtrl', ['$scope', 'preferences', 'Message',
  ($scope, preferences, Message) ->

    $scope.visible = false
    $scope.page = 1
    $scope.rpp = 10

    $scope.messages = []

    $scope.$watch 'conversation', (newValue, oldValue) ->
      $scope.loadConversation() if $scope.conversation && newValue != oldValue

    $scope.$watchCollection 'messages', (newValue, oldValue) ->
      $scope.$broadcast('scrollConversationToNewest' + $scope.qualifier()) if $scope.conversation && newValue != oldValue

    $scope.$watch 'senderIdQuery', (newValue, oldValue) ->
      $scope.page = 1
      $scope.messages = []
      $scope.totalItems = 0
      $scope.fetchPage() if newValue

    $scope.close = ->
      $scope.visible = false

    $scope.qualifier = ->
      senderId = $scope.conversation.sender_id
      recipientId = $scope.conversation.recipient_id
      if senderId > recipientId then (recipientId + '_' + senderId) else (senderId + '_' + recipientId)

    $scope.fetchPage = ->
      page = $scope.page++
      response = Message.paginate sender_id: $scope.senderIdQuery, recipient_id: $scope.senderIdQuery, page: page, rpp: $scope.rpp
      if response && response.$promise
        response.$promise.then ->
          for message in response.results
            $scope.messages.push(message)
          $scope.totalItems = response.totalResults
          $scope.showActivity = false
          $scope.$broadcast('scrollConversationToNewest' + $scope.qualifier()) if $scope.conversation && page == 1

    $scope.loadConversation = ->
      $scope.visible = true
      $scope.senderIdQuery = $scope.conversation.sender_id + '|' + $scope.conversation.recipient_id

    $scope.sendMessage = (message) ->
      userIds = $scope.senderIdQuery.split('|')
      recipientId = null
      for userId in userIds
        recipientId = userId if preferences.get('x-api-user-id') != userId
      message = new Message(recipient_id: recipientId, body: message) if recipientId
      promise = message.$save()
      promise.then ->
        $scope.messages.push(message)

]
