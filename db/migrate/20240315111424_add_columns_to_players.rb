class AddColumnsToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :solved, :boolean, default: false
    add_column :players, :answered, :boolean, default: false
  end
end
