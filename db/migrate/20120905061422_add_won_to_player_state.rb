class AddWonToPlayerState < ActiveRecord::Migration
  def change
    add_column :player_states, :won, :boolean, :default => false
  end
end
