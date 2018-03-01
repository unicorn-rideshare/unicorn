module = angular.module('unicornApp.controllers')

module.controller 'ProviderCheckinMapCtrl', ['$scope', '$routeParams', 'Provider', 'Checkin', 'companyPreference',
  ($scope, $routeParams, Provider, Checkin, companyPreference) ->
    $scope.providersByUserId = {}
    $scope.infoNotice = null

    $scope.visibleRoutes = {}
    $scope.showTimesheet = false

    providers = Provider.query company_id: companyPreference.get(), ->
      $scope.renderMap()

      providers.$promise.then ->
        $scope.providers = providers

        for provider in $scope.providers
          $scope.providersByUserId[provider.user_id] = provider

          if provider.last_checkin
            provider.marker = $scope.createMarker(provider)

            provider.infoWindow = new google.maps.InfoWindow
              content: provider.contact.name + ' hasn\'t checked in.'

            google.maps.event.addListener provider.marker, 'click', ->
              provider.infoWindow.open($scope.map, provider.marker)

        $scope.zoomToBestFit()

    $scope.renderMap = ->
      unless $scope.map
        defaultOptions =
          center: new google.maps.LatLng(33.75, -84.39)
          zoom: 9
        canvas = document.getElementById('map-canvas')
        $scope.map = new google.maps.Map(canvas, defaultOptions) if canvas

    $scope.zoomToBestFit = ->
      markers = []
      for userId, provider of $scope.providersByUserId
        markers.push(provider.marker) if provider.marker
      if markers.length > 0
        bounds = new google.maps.LatLngBounds()
        for marker in markers
          bounds.extend(marker.position)
        $scope.map.fitBounds(bounds)

    $scope.createMarker = (provider) ->
      checkin = provider.last_checkin

      image =
        url: provider.profile_image_url
        scaledSize: new google.maps.Size(50, 50),
        origin: new google.maps.Point(0, 0),

      new google.maps.Marker(
        position: new google.maps.LatLng(checkin.latitude, checkin.longitude),
        map: $scope.map,
        title: provider.contact.name,
        icon: image
      )

    $scope.renderRouteHistory = ->
      routeCoordinates = []
      for checkin in $scope.checkins
        coordinate = new google.maps.LatLng(checkin.latitude, checkin.longitude)
        routeCoordinates.push(coordinate)

      routeMarkers = []
      for checkin, i in $scope.checkins
        marker = new google.maps.Marker(
          position: new google.maps.LatLng(checkin.latitude, checkin.longitude),
          map: $scope.map,
          title: checkin.checkin_at,
          icon: if i == 0 then $scope.providersByUserId[checkin.user_id].profile_image_url else null,
          zIndex: 10000 - i
        )
        routeMarkers.push(marker)

      routePath = new google.maps.Polyline({
        path: routeCoordinates,
        geodesic: true,
        strokeColor: 'darkBlue',
        strokeOpacity: 1.0,
        strokeWeight: 1
      })

      routePath.setMap($scope.map)

    $scope.panTo = (userId) ->
      $scope.infoNotice = null

      provider = $scope.providersByUserId[userId]
      if provider
        if provider.marker && provider.marker.getPosition() != null
          $scope.map.panTo(provider.marker.getPosition())
        else
          $scope.infoNotice = provider.contact.name + ' hasn\'t checked in.'

    $scope.viewRoute = (userId) ->
      provider = $scope.providersByUserId[userId]
      console.log('route view requested for provider: ' + provider)

    $scope.viewTimesheet = (userId) ->
      $scope.showTimesheet = true
      provider = $scope.providersByUserId[userId]
      console.log('timesheet view requested for provider: ' + provider)
]
