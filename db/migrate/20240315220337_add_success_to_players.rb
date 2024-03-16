class AddSuccessToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :success, :boolean
  end
end
