module = angular.module('unicornApp.services')

module.factory '$localStorage', ->
  localStorage

module.factory '$sessionStorage', ->
  sessionStorage
