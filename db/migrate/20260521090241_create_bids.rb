class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.references :stack_asset, null: false, foreign_key: true
      t.string :bidder_name
      t.decimal :amount
      t.datetime :timestamp

      t.timestamps
    end
  end
end
