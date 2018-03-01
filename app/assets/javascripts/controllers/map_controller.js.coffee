module = angular.module('unicornApp.controllers')

module.controller 'MapCtrl', ['$scope', '$controller',
  ($scope, $controller) ->

    $scope.renderMap = ->
      unless $scope.map
        defaultOptions =
          center: $scope.centerLatLng
          zoom: 9

      $scope.map = new google.maps.Map(document.getElementById($scope.elementId), defaultOptions)

    $scope.createMarker = (latitude, longitude, title, icon) ->
      new google.maps.Marker(
        position: new google.maps.LatLng(latitude, longitude),
        map: $scope.map,
        title: title,
        icon: icon
      )

    $scope.renderPolyline = (coordinates) ->
      path = new google.maps.Polyline({
        path: coordinates,
        geodesic: true,
        strokeColor: 'darkBlue',
        strokeOpacity: 1.0,
        strokeWeight: 1
      })

      path.setMap($scope.map)
]
