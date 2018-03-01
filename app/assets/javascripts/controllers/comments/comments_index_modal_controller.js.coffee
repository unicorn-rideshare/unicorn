module = angular.module('unicornApp.controllers')

module.controller 'CommentsIndexModalCtrl', ['$scope', '$controller', '$modalInstance', 'Comment', 'commentable', 'commentableUri'
  ($scope, $controller, $modalInstance, Comment, commentable, commentableUri) ->
    $.extend this, $controller('IndexCtrl', { $scope: $scope })

    $scope.collectionClass = Comment
    $scope.collectionName = 'comments'

    $scope.commentable = commentable

    $scope.comments = []

    $scope.queryParams = ->
      { commentable_id: $scope.commentable.id, commentable_type: commentableUri }

    $scope.query()

    $scope.addComment = (comment) ->
      comment = new Comment(commentable_type: commentableUri, commentable_id: $scope.commentable.id, body: comment)
      promise = comment.$save()
      promise.then ->
        $scope.comments.push(comment)

    $scope.cancel = ->
      $modalInstance.dismiss()
]
