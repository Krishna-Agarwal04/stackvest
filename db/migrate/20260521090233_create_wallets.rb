class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.decimal :balance

      t.timestamps
    end
  end
end
