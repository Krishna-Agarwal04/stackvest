class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount
      t.string :transaction_type
      t.string :description
      t.datetime :timestamp

      t.timestamps
    end
  end
end
