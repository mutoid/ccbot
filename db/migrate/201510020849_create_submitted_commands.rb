class CreateSubmittedCommands < ActiveRecord::Migration
  def change
    create_table :run_commands do |t|
      t.string :user_name
      t.string :user_id
      t.string :command
      t.timestamps null: false
    end
  end
end
