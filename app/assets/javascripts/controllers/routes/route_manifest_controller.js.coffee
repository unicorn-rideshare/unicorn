module = angular.module('unicornApp.controllers')

module.controller 'RouteManifestModalCtrl', ['$scope', '$modalInstance', 'route', 'workOrder',
  ($scope, $modalInstance, route, workOrder) ->
    $scope.route = route
    $scope.workOrder = workOrder

    $scope.filter =
      includeLoadedItems: false

    $scope.$watch 'filter.includeLoadedItems', (newValue, oldValue) ->
      $scope.filterManifest() if newValue != oldValue

    $scope.itemsToDisplay = []

    $scope.itemsOrdered = []
    $scope.itemsLoaded = []

    $scope.itemsOrderedCountByGtin = {}
    $scope.itemsLoadedCountByGtin = {}

    $scope.uniqueItemsOrdered = []
    $scope.uniqueItemsLoaded = []

    $scope.uniqueGtinsRendered = []

    $scope.resolveItemsOrdered = ->
      itemsOrdered = []
      if $scope.workOrder
        itemsOrdered = $scope.workOrder.items_ordered
      else
        for workOrder in $scope.route.work_orders
          for itemOrdered in workOrder.items_ordered
            itemsOrdered.push(itemOrdered)
      $scope.itemsOrdered = itemsOrdered.reverse()
      $scope.uniqueItemsOrdered = []
      $scope.itemsOrderedCountByGtin = {}
      for itemOrdered in $scope.itemsOrdered
        if $scope.uniqueItemsOrdered.indexOf(itemOrdered) == -1
          $scope.uniqueItemsOrdered.push(itemOrdered)
        if !$scope.itemsOrderedCountByGtin[itemOrdered.gtin]
          $scope.itemsOrderedCountByGtin[itemOrdered.gtin] = 0
        $scope.itemsOrderedCountByGtin[itemOrdered.gtin]++
      $scope.filterManifest()

    $scope.resolveItemsLoaded = ->
      $scope.itemsLoaded = $scope.route.items_loaded
      $scope.uniqueItemsLoaded = []
      $scope.itemsLoadedCountByGtin = {}
      for itemLoaded in $scope.itemsLoaded
        if $scope.uniqueItemsLoaded.indexOf(itemLoaded) == -1
          $scope.uniqueItemsLoaded.push(itemLoaded)
        if !$scope.itemsLoadedCountByGtin[itemLoaded.gtin]
          $scope.itemsLoadedCountByGtin[itemLoaded.gtin] = 0
        $scope.itemsLoadedCountByGtin[itemLoaded.gtin]++

    $scope.gtinOrderedCount = (gtin) ->
      count = 0
      for itemOrdered in $scope.itemsOrdered
        count += 1 if itemOrdered.gtin == gtin
      count

    $scope.itemsToLoadCountRemainingForGtin = (gtin) ->
      itemsOrderedCountByGtin = $scope.itemsOrderedCountByGtin[gtin] || 0
      itemsLoadedCountByGtin = $scope.itemsLoadedCountByGtin[gtin] || 0
      itemsOrderedCountByGtin - itemsLoadedCountByGtin

    $scope.isGtinLoaded = (gtin) ->
      gtinLoadedCount = 0
      for itemLoaded in $scope.itemsLoaded
        return true if itemLoaded.gtin == gtin
      false

    $scope.isGtinRequired = (gtin) ->
      gtinLoadedCount = 0
      for itemLoaded in $scope.itemsLoaded
        gtinLoadedCount += 1 if itemLoaded.gtin == gtin
      $scope.gtinOrderedCount(gtin) == gtinLoadedCount

    $scope.filterManifest = ->
      itemsToDisplay = []
      $scope.uniqueGtinsRendered = []
      for item in $scope.uniqueItemsOrdered
        if $scope.shouldRenderItemForGtin(item.gtin)
          $scope.uniqueGtinsRendered.push(item.gtin)
          itemsToDisplay.push(item) if $scope.itemsToLoadCountRemainingForGtin(item.gtin) > 0 || $scope.filter.includeLoadedItems
      $scope.itemsToDisplay = itemsToDisplay

    $scope.shouldRenderItemForGtin = (gtin) ->
      $scope.uniqueGtinsRendered.indexOf(gtin) == -1

    $scope.cancel = ->
      $modalInstance.dismiss()

    $scope.$watch 'route', ->
      $scope.resolveItemsOrdered()
      $scope.resolveItemsLoaded()

    $scope.$watch 'workOrder', ->
      $scope.resolveItemsOrdered()
]
