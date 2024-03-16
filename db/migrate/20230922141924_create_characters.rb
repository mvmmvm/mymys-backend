# frozen_string_literal: true

class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters do |t|
      t.references :story, null: false, foreign_key: true
      t.string :name
      t.string :gender
      t.text :personality
      t.string :job
      t.text :introduce
      t.string :stuff
      t.text :evidence, array: true
      t.boolean :is_criminal
      t.timestamps
    end
  end
end
