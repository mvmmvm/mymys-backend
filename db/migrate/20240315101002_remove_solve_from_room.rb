# frozen_string_literal: true

class RemoveSolveFromRoom < ActiveRecord::Migration[7.0]
  def change
    remove_column :rooms, :solved
  end
end
