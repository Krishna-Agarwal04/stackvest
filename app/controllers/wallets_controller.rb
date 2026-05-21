class WalletsController < ApplicationController
  # GET /api/wallet
  def show
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)
    render json: wallet
  end

  # POST /api/wallet/deposit
  def deposit
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)
    amount = params[:amount].to_f

    if amount <= 0
      render json: { error: "Deposit amount must be positive" }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      wallet.increment!(:balance, amount)
      Transaction.create!(
        amount: amount,
        transaction_type: "deposit",
        description: "Venture Capital Cash Injection",
        timestamp: Time.current
      )
    end

    render json: { wallet: wallet, message: "Funds successfully injected!" }
  end
end
