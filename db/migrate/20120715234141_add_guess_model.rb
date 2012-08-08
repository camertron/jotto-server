class AddGuessModel < ActiveRecord::Migration
  def change
    create_table :guesses do |t|
      t.column :player_state_id, :integer
      t.column :word, :string
      t.column :count, :integer
      t.timestamps
    end
  end
end
