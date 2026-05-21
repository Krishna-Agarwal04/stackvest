class MockBidderService
  RIVAL_NAMES = [
    "Silicon Venture Capital",
    "DeFi Whale 7",
    "Bootstrap Bandit",
    "Venture Scale Partners",
    "Y-Combinator Grad",
    "Angel Syndicate",
    "Alpha Tech Fund",
    "Apex Holdings",
    "Web3 Bull"
  ].freeze

  def self.trigger_simulated_bids
    # Find all assets in active auction
    assets = StackAsset.where(status: 'active_auction')
    bids_placed = false

    assets.each do |asset|
      # 30% chance a rival places a counter-bid on any active auction
      next unless rand < 0.30

      # Determine bid increment: 2% to 8% of current bid, or flat $1,000-$5,000
      current = asset.current_bid.to_f > 0 ? asset.current_bid.to_f : asset.valuation.to_f
      increment = (rand(10..50) * 100).to_f # Increments of $100 up to $5,000
      new_bid_amount = current + increment

      # Select a random rival name
      rival_name = RIVAL_NAMES.sample

      # If the rival is already the highest bidder, don't bid against themselves
      next if asset.highest_bidder == rival_name

      # Create the Bid record
      Bid.create!(
        stack_asset: asset,
        bidder_name: rival_name,
        amount: new_bid_amount,
        timestamp: Time.current
      )

      # Update the stack asset
      asset.update!(
        current_bid: new_bid_amount,
        highest_bidder: rival_name
      )
      bids_placed = true
    end

    bids_placed
  end

  # Helper method to run simulated weekly dividends/ROI payouts for owned assets
  def self.payout_dividends
    owned_assets = StackAsset.where(status: 'owned')
    wallet = Wallet.first
    return unless wallet && owned_assets.any?

    total_payout = 0.0

    owned_assets.each do |asset|
      # Yield is a monthly percentage, so a single payout (e.g. weekly) is roughly monthly_roi / 4
      payout_rate = (asset.monthly_roi.to_f / 100.0) / 4.0
      payout_amount = (asset.valuation.to_f * payout_rate).round(2)
      next if payout_amount <= 0

      # Accumulate earnings on the asset
      asset.increment!(:earnings, payout_amount)

      # Log transaction
      Transaction.create!(
        amount: payout_amount,
        transaction_type: "dividend",
        description: "Weekly yield payout from '#{asset.name}'",
        timestamp: Time.current
      )

      total_payout += payout_amount
    end

    if total_payout > 0
      wallet.increment!(:balance, total_payout)
    end

    total_payout
  end
end
