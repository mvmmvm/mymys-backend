class AddColumnsToRoom < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :solve, :integer, default: 0
    add_column :rooms, :answer, :integer, default: 0
  end
end
