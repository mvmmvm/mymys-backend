class CreatePlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.references :room, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.string :name, :null => false
      t.timestamps
    end
  end
end
