class WorkOrdersController < ApplicationController
  load_and_authorize_resource
  skip_before_action :authenticate_user!, only: [:show]
  layout 'customer'

  def show
    @work_order_json = Rabl::Renderer.new('work_orders/show',
                                          @work_order,
                                          view_path: 'app/views',
                                          format: 'json').render
  end
end
