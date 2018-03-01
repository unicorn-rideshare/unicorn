module = angular.module('unicornApp.controllers')

module.controller 'MessagesIndexCtrl', ['$scope', '$controller', '$compile', '$timeout', 'preferences', 'websocket', 'Message',
  ($scope, $controller, $compile, $timeout, preferences, websocket, Message) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.showActivity = true

    $scope.collectionClass = Message
    $scope.collectionName = 'messages'

    $scope.messages = []

    $scope.$watch 'messages', (newValue, oldValue) ->
      for message in newValue
        $scope.renderConversation(message)

    $scope.$on 'message_received', (event, message) ->
      $scope.query()
      qualifier = $scope.qualifier(message)
      $scope.$broadcast('appendMessageToConversation' + qualifier, message)

    $scope.$on 'startConversation', (event, params) ->
      message = new Message(sender_id: preferences.get('x-api-user-id'), recipient_id: params.userId, recipient_name: params.name)
      qualifier = $scope.qualifier(message)
      $scope.renderConversation(message) unless $scope.conversationElements[qualifier]
      fn = -> $scope.openConversation(message)
      $timeout(fn)

    $scope.renderConversation = (message) ->
      qualifier = $scope.qualifier(message)
      if !$scope.conversationElements[qualifier]
        conversationElement = $compile('<conversation message-id="' + message.id + '" sender-id="' + message.sender_id + '" recipient-id="' + message.recipient_id + '" />')($scope)
        document.body.appendChild(conversationElement[0])
        $scope.conversationElements[qualifier] = conversationElement
        $scope.openConversation(message)

    $scope.openConversation = (conversation, $event) ->
      qualifier = $scope.qualifier(conversation)
      $scope.$broadcast('loadConversation' + qualifier, conversation)

    $scope.qualifier = (message) ->
      if message.sender_id > message.recipient_id then (message.recipient_id + '_' + message.sender_id) else (message.sender_id + '_' + message.recipient_id)

    $scope.queryParams = ->
      { }

    $scope.query = () ->
      $scope.showActivity = true

      params = $scope.queryParams()
      params.page = $scope.page
      params.rpp = $scope.rpp

      response = $scope.collectionClass.conversations(params)
      if response && response.$promise
        response.$promise.then ->
          $scope[$scope.collectionName] = response.results if $scope.collectionName
          $scope.totalItems = response.totalResults
          $scope.showActivity = false

    $scope.query()
]
