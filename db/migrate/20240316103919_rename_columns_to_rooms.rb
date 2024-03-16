# frozen_string_literal: true

class RenameColumnsToRooms < ActiveRecord::Migration[7.0]
  def change
    rename_column :rooms, :solve, :solve_count
    rename_column :rooms, :answer, :answer_count
  end
end
