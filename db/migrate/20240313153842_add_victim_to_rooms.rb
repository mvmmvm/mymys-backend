# frozen_string_literal: true

class AddVictimToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :status, :integer, default: 0
  end
end
