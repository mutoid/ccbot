class CreatePins < ActiveRecord::Migration
  def change
    create_table :pins do |t|
      t.string :author_id
      t.string :author_name
      t.string :pinner_id
      t.string :pinner_name
      t.text :text
      t.string :channel_id
      t.string :channel_name
      t.string :slack_timestamp, :unique => true
      t.timestamps null: false
    end
  end
end
