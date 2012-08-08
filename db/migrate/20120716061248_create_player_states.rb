class CreatePlayerStates < ActiveRecord::Migration
  def change
    create_table :player_states do |t|
      t.column :game_id, :integer
      t.column :word, :string
      t.column :board, :string
      t.column :player, :string
      t.timestamps
    end
  end
end
