class TransactionsController < ApplicationController
  # GET /api/transactions
  def index
    transactions = Transaction.order(timestamp: :desc).limit(50)
    render json: transactions
  end
end
