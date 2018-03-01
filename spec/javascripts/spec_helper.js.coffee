#= require application
#= require provide
#= require_tree ./support

# TODO: Convert this to a module that can be included in each spec
# e.g. angular.module('unicornApp.mocks')

beforeEach ->
  module ($provide) ->

    $provide.factory '$scope', ($rootScope) -> $rootScope.$new()
    $provide.value 'defaultCompanyId', 9999

    undefined
