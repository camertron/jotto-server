class ChangePlayerToName < ActiveRecord::Migration
  def up
    rename_column :player_states, :player, :name
  end

  def down
    rename_column :player_states, :name, :player
  end
end