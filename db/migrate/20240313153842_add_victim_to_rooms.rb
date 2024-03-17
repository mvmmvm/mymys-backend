# frozen_string_literal: true

class AddVictimToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :victim, :string
  end
end
