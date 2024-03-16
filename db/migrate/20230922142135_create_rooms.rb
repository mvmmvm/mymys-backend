# frozen_string_literal: true

class CreateRooms < ActiveRecord::Migration[7.0]
  def change
    create_table :rooms do |t|
      t.references :story, null: true, foreign_key: true
      t.boolean :solved
      t.timestamps
    end
  end
end
