class CreateStackAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :stack_assets do |t|
      t.string :name
      t.string :technologies
      t.text :description
      t.decimal :valuation
      t.decimal :monthly_roi
      t.string :risk_level
      t.string :status
      t.decimal :current_bid
      t.string :highest_bidder
      t.string :owner_name
      t.string :image_url
      t.decimal :earnings

      t.timestamps
    end
  end
end
