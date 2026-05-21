class DashboardController < ApplicationController
  # GET /api/dashboard
  def index
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)
    owned_assets = StackAsset.where(status: 'owned')
    active_auctions = StackAsset.where(status: 'active_auction')

    cash = wallet.balance.to_f
    portfolio_value = owned_assets.sum(:valuation).to_f
    net_worth = cash + portfolio_value
    total_yield_earnings = owned_assets.sum(:earnings).to_f
    
    # Active bids count: auctions where user is currently the highest bidder
    active_bids_count = active_auctions.where(highest_bidder: "You").count

    # Generate historical net worth data for the last 7 days
    # To make this robust, we start with today's net worth and walk backwards
    # using transaction logs to reconstruct net worth at the end of each day!
    daily_net_worth = []
    current_val = net_worth

    # Reconstruct history
    (0..6).each do |days_ago|
      date = days_ago.days.ago.to_date
      
      # Sum of transactions that happened *after* the end of this historical date
      # to subtract from current value
      tx_sum_after = Transaction.where("timestamp > ?", date.end_of_day).sum(:amount).to_f
      
      # The value on that date was (current value - future transaction movements)
      # Since transaction purchases are negative, subtracting a negative means adding it back (which is correct!)
      historical_val = net_worth - tx_sum_after
      
      daily_net_worth.unshift({
        date: date.strftime("%b %d"),
        value: historical_val.round(2)
      })
    end

    # Group asset values for allocation chart (technologies or risk level distribution)
    # Let's group owned assets by risk level
    risk_distribution = { Low: 0.0, Medium: 0.0, High: 0.0 }
    owned_assets.each do |asset|
      risk = asset.risk_level.to_sym
      risk_distribution[risk] += asset.valuation.to_f if risk_distribution.key?(risk)
    end

    render json: {
      metrics: {
        cash: cash,
        portfolio_value: portfolio_value,
        net_worth: net_worth,
        total_yield_earnings: total_yield_earnings,
        active_bids_count: active_bids_count,
        owned_stacks_count: owned_assets.count
      },
      chart_data: daily_net_worth,
      risk_distribution: [
        { label: "Low Risk", value: risk_distribution[:Low] },
        { label: "Medium Risk", value: risk_distribution[:Medium] },
        { label: "High Risk", value: risk_distribution[:High] }
      ],
      recent_transactions: Transaction.order(timestamp: :desc).limit(5)
    }
  end
end
