class AddDeviceToken < ActiveRecord::Migration
  def up
    add_column :player_states, :device_token, :string, :null => true
  end

  def down
    remove_column :player_states, :device_token
  end
end
