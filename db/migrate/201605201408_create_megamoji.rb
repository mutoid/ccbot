class CreateMegamoji < ActiveRecord::Migration
  def change
    create_table :megamojis do |t|
      t.string :base_name
      t.integer :width
      t.integer :count
      t.timestamps null: false
    end
  end
end
