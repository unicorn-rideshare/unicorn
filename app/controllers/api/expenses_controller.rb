module Api
  class ExpensesController < Api::ApplicationController
    load_resource :job
    load_resource :work_order
    before_action :authorize_parent
    load_and_authorize_resource through: [:job, :work_order]

    def index
      @expenses = filter_by(@expenses, indexes)
      respond_with(:api, @expenses)
    end

    def create
      @expense.user = current_user
      @expense.save && true
      respond_with(:api, @expense, template: 'api/expenses/show', status: :created)
    end

    private

    def authorize_parent
      authorize! :read, (@job || @work_order)
    end

    def indexes
      [:user_id, [:expensable_id, :expensable_type]]
    end

    def expense_params
      params.permit(:amount, :description, :incurred_at)
    end
  end
end
