class AddGameModel < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.column :name, :string
      t.column :player1, :integer
      t.column :player2, :integer
      t.timestamps
    end
  end
end
