module = angular.module('unicornApp.services')

module.factory 's3', ['$http',
  ($http) ->
    presign: (file, metadata) ->
      filename = file.name || metadata.filename
      presignedUrl = '/api/s3/presign?filename=' + filename
      presignedUrl += '&metadata=' + encodeURIComponent(JSON.stringify(metadata)) if metadata && Object.keys(metadata).length > 0
      $http.get(presignedUrl)

    upload: (presignedUrl, file, params) ->
      multipart = new FormData()
      fields = params.fields
      for key, value of fields
        multipart.append(key, value)
      multipart.append('file', file)
      $http.post(presignedUrl, multipart, { transformRequest: angular.identity, headers: { 'Content-Type': undefined } }) # this ensures angular leaves our data alone
]
