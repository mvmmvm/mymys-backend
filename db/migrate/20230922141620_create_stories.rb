class CreateStories < ActiveRecord::Migration[7.0]
  def change
    create_table :stories do |t|
      t.string :name
      t.string :set
      t.text :body
      t.string :weapon
      t.string :place
      t.string :time
      t.string :victim
      t.string :v_gender
      t.string :v_personality
      t.string :v_job
      t.text :confession
      t.text :all
      t.timestamps
    end
  end
end
