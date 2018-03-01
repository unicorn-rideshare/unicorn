#= require_self
#= require_tree ./services

module = angular.module('unicornApp.services', ['ngResource', 'ngCookies', 'base64'])

paginateAction =
  cancellable: true
  transformResponse: [
    (data, headers) ->
      status: if headers()['x-api-status'] then parseInt(headers()['x-api-status']) else null
      results: JSON.parse(data)
      totalResults: if headers()['x-total-results-count'] then parseInt(headers()['x-total-results-count']) else null
  ]

module.factory 'Attachment', ['$resource',
  ($resource) ->
    $resource '/api/:attachable_type/:attachable_id/attachments/:id', { attachable_type: '@attachable_type', attachable_id: '@attachable_id', id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Category', ['$resource',
  ($resource) ->
    $resource '/api/categories/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Checkin', ['$resource',
  ($resource) ->
    $resource '/api/checkins/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Comment', ['$resource',
  ($resource) ->
    $resource '/api/:commentable_type/:commentable_id/comments/:id', { commentable_type: '@commentable_type', commentable_id: '@commentable_id', id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Company', ['$resource',
  ($resource) ->
    $resource '/api/companies/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Customer', ['$resource',
  ($resource) ->
    $resource '/api/customers/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Directions', ['$resource',
  ($resource) ->
    $resource '/api/directions', { id: '@id' }, {
      'eta': { method: 'GET', url: '/api/directions/eta' }
    }
]

module.factory 'Dispatcher', ['$resource',
  ($resource) ->
    $resource '/api/dispatchers/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'DispatcherOriginAssignment', ['$resource',
  ($resource) ->
    $resource '/api/markets/:market_id/origins/:origin_id/dispatcher_origin_assignments/:id', { market_id: '@market_id', origin_id: '@origin_id', id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Market', ['$resource',
  ($resource) ->
    $resource '/api/markets/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Message', ['$resource',
  ($resource) ->
    $resource '/api/messages/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' },
      'conversations': { method: 'GET', url: '/api/messages/conversations', transformResponse: paginateAction.transformResponse }
    }
]

module.factory 'Origin', ['$resource',
  ($resource) ->
    $resource '/api/markets/:market_id/origins/:id', { market_id: '@market_id', id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Product', ['$resource',
  ($resource) ->
    $resource '/api/products/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Provider', ['$resource',
  ($resource) ->
    $resource '/api/providers/:id', { id: '@id' }, {
      'paginate': paginateAction
      'availability': { method: 'GET', isArray: true, url: '/api/providers/availability' }
      'update': { method: 'PUT' }
    }
]

module.factory 'ProviderOriginAssignment', ['$resource',
  ($resource) ->
    $resource '/api/markets/:market_id/origins/:origin_id/provider_origin_assignments/:id', { market_id: '@market_id', origin_id: '@origin_id', id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Recaptcha', ['$resource',
  ($resource) ->
    $resource '/api/recaptcha', { }, {
      'verify': { method: 'POST' }
    }
]

module.factory 'Route', ['$resource',
  ($resource) ->
    $resource '/api/routes/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Token', ['$resource',
  ($resource) ->
    $resource '/api/tokens/:id', { id: '@id' }
]

module.factory 'User', ['$resource',
  ($resource) ->
    $resource '/api/users/:id', { id: '@id' }, {
      'update': { method: 'PUT' },
      'reset_password': { method: 'POST', url: '/api/users/reset_password' }
    }
]

module.factory 'WorkOrder', ['$resource',
  ($resource) ->
    $resource '/api/work_orders/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]

module.factory 'Job', ['$resource',
  ($resource) ->
    $resource '/api/jobs/:id', { id: '@id' }, {
      'paginate': paginateAction
      'update': { method: 'PUT' }
    }
]
