module = angular.module('unicornApp.controllers')

module.controller 'NewAttachmentModalCtrl', ['$scope', '$controller', '$modalInstance', '$http', 'Attachment', 'attachable', 'attachableUri', 'tags', 'onAttachmentCreated', 's3'
  ($scope, $controller, $modalInstance, $http, Attachment, attachable, attachableUri, tags, onAttachmentCreated, s3) ->

    $scope.attachable = attachable

    $scope.file = null
    $scope.tags = tags
    $scope.enableTags = !tags

    $scope.validFileExtensions = ['png', 'jpg', 'pdf', 'mp4', 'm4v', 'mov']
    $scope.maxFileSize = 26214400

    $scope.uploading = false

    $scope.cancel = ->
      $modalInstance.dismiss()

    $scope.$watch 'file', (newValue, oldValue) ->
      if newValue && !$scope.uploading
        $scope.uploading = true
        $scope.upload(newValue).then ->
          #$scope.uploading = false

    $scope.setFile = (file) ->
      $scope.file = file

    $scope.setTags = (tags) ->
      $scope.tags = tags

    $scope.fileInputChanged = (ele) ->
      $scope.uploading = true
      files = ele.files
      if files[0]
        $scope.uploading = true
        $scope.upload(files[0]).then ->
          #$scope.uploading = false

    $scope.validateFileType = (file) ->
      parts = file.name.split('.')
      return false if parts.length < 2
      lastPart = parts[parts.length - 1].toLowerCase()
      for ext in this.validFileExtensions
        return true if ext == lastPart
      false

    $scope.submit = ->
      $scope.upload($scope.file)

    $scope.validateFileSize = (file) ->
      return (file.size < $scope.maxFileSize)

    $scope.upload = (file) ->
      #usSpinnerService.spin('appSpinner')
      $scope.file = file
      if $scope.file
        if $scope.validateFileSize($scope.file)
          if $scope.validateFileType($scope.file)
            metadata =
              tags: if $scope.tags && $scope.tags.length > 0 then $scope.tags else null
            ps_promise = s3.presign(attachableUri, $scope.attachable.id, $scope.file, metadata)
            ps_promise.success (data, status, headers, config) ->
              if status == 200
                url = data.url
                params = data.signed_headers
                params.metadata = metadata
                s3_promise = s3.upload(url, $scope.file, params)
                s3_promise.success (data2, status, headers, config) ->
                  if status == 204
                    params =
                      key: data.fields.key
                      mime_type: data.fields['Content-Type']
                      tags: $scope.tags
                      url: url + data.fields.key
                    promise = $http.post('/api/' + attachableUri + '/' + $scope.attachable.id + '/attachments', params) # FIXME-- convert to services.js.coffee
                    promise.success (data3, status, headers, config) ->
                      #usSpinnerService.stop('appSpinner')
                      if status == 201
                        onAttachmentCreated(data3)
                        $scope.$close()
                      else
                        alert "Unable to complete the upload. Please try again."
                        console.log('failed to create native attachment')
                s3_promise.error (data, status, headers, config) ->
                  #usSpinnerService.stop('appSpinner')
                  alert "Unable to complete the upload. Please try again."
                  console.log('failed to upload attachment to s3')
            ps_promise.error (data, status, headers, config) ->
              #usSpinnerService.stop('appSpinner')
              alert "Unable to complete the upload. Please try again."
              console.log('failed to presign attachment for s3 upload')
          else
            #usSpinnerService.stop('appSpinner')
            alert "This is not an acceptable file type."
        else
          #usSpinnerService.stop('appSpinner')
          alert "The file you are attempting to upload is too large. Pass It Down accepts file up to 25 MB in size."
]
