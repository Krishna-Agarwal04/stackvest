class StacksController < ApplicationController
  # GET /api/stacks
  def index
    # Randomly simulate some counter-bids in the background on index requests
    # to make the bidding feel dynamic as the user browses!
    if params[:simulate] == "true"
      MockBidderService.trigger_simulated_bids
    end

    stacks = StackAsset.all
    render json: stacks.map { |stack| format_stack(stack) }
  end

  # GET /api/stacks/:id
  def show
    stack = StackAsset.find(params[:id])
    bids = stack.bids.order(amount: :desc)
    render json: {
      stack: format_stack(stack),
      bids: bids
    }
  end

  # POST /api/stacks/:id/bid
  def place_bid
    stack = StackAsset.find(params[:id])
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)
    bid_amount = params[:amount].to_f

    if stack.status != 'active_auction'
      render json: { error: "This stack is not currently up for auction" }, status: :unprocessable_entity
      return
    end

    min_bid = stack.current_bid.to_f > 0 ? stack.current_bid.to_f : stack.valuation.to_f
    if bid_amount <= min_bid
      render json: { error: "Bid must be higher than the current high bid of $#{min_bid}" }, status: :unprocessable_entity
      return
    end

    if wallet.balance.to_f < bid_amount
      render json: { error: "Insufficient wallet balance. You need $#{bid_amount} but only have $#{wallet.balance}" }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      # Note: For simple design, we don't lock/freeze funds until the auction ends.
      # But we register the bid!
      Bid.create!(
        stack_asset: stack,
        bidder_name: "You",
        amount: bid_amount,
        timestamp: Time.current
      )

      stack.update!(
        current_bid: bid_amount,
        highest_bidder: "You"
      )
    end

    # Proactively trigger a competitor to counter-bid immediately with a 40% probability
    # to create an exciting real-time response!
    if rand < 0.40
      # Wait a fraction of a second or trigger in thread, but simple trigger is fine:
      MockBidderService.trigger_simulated_bids
      stack.reload
    end

    render json: {
      stack: format_stack(stack),
      wallet: wallet,
      message: "Bid successfully placed!"
    }
  end

  # POST /api/stacks/:id/buy
  def buy_outright
    stack = StackAsset.find(params[:id])
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)
    
    # Cost is the current_bid if active, otherwise base valuation
    cost = (stack.status == 'active_auction' && stack.current_bid.to_f > 0) ? stack.current_bid.to_f : stack.valuation.to_f

    if wallet.balance.to_f < cost
      render json: { error: "Insufficient wallet balance to buy this stack. Cost: $#{cost}, Balance: $#{wallet.balance}" }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      wallet.decrement!(:balance, cost)
      stack.update!(
        status: 'owned',
        owner_name: 'You',
        valuation: cost, # Locked-in value becomes what we paid
        current_bid: 0.0,
        highest_bidder: nil
      )

      # Log purchase transaction
      Transaction.create!(
        amount: -cost,
        transaction_type: "purchase",
        description: "Purchased Tech Stack: '#{stack.name}'",
        timestamp: Time.current
      )
    end

    render json: {
      stack: format_stack(stack),
      wallet: wallet,
      message: "Congratulations! You now own '#{stack.name}'!"
    }
  end

  # POST /api/stacks/:id/sell
  def sell
    stack = StackAsset.find(params[:id])
    wallet = Wallet.first || Wallet.create!(balance: 100000.0)

    if stack.status != 'owned' || stack.owner_name != 'You'
      render json: { error: "You do not own this stack to sell it" }, status: :unprocessable_entity
      return
    end

    payout = stack.valuation.to_f

    ActiveRecord::Base.transaction do
      wallet.increment!(:balance, payout)
      
      # Put it back on the auction block with base valuation
      stack.update!(
        status: 'active_auction',
        owner_name: nil,
        current_bid: payout * 0.9, # start auction slightly lower
        highest_bidder: "Seed Investor",
        earnings: 0.0 # Reset historical yield earnings
      )

      # Log liquidation transaction
      Transaction.create!(
        amount: payout,
        transaction_type: "liquidation",
        description: "Liquidated Portfolio Stack: '#{stack.name}'",
        timestamp: Time.current
      )
    end

    render json: {
      stack: format_stack(stack),
      wallet: wallet,
      message: "Successfully liquidated '#{stack.name}' for $#{payout}!"
    }
  end

  # POST /api/stacks/payout_yields
  def payout_yields
    payout = MockBidderService.payout_dividends
    wallet = Wallet.first
    render json: {
      payout: payout,
      wallet: wallet,
      message: payout > 0 ? "Payout complete! Credited $#{payout} to wallet." : "No owned assets generated yields. Buy active stacks!"
    }
  end

  private

  def format_stack(stack)
    {
      id: stack.id,
      name: stack.name,
      technologies: stack.technologies,
      technologies_list: stack.technologies_list,
      description: stack.description,
      valuation: stack.valuation,
      monthly_roi: stack.monthly_roi,
      risk_level: stack.risk_level,
      status: stack.status,
      current_bid: stack.current_bid,
      highest_bidder: stack.highest_bidder,
      owner_name: stack.owner_name,
      image_url: stack.image_url,
      earnings: stack.earnings,
      created_at: stack.created_at,
      updated_at: stack.updated_at
    }
  end
end
