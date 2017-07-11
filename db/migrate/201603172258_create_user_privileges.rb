class CreateUserPrivileges < ActiveRecord::Migration
  def change
    create_table :user_privileges do |t|
      t.string :user_id
      t.integer :power_user
      t.integer :admin_user
      t.timestamps null: false
    end
  end
end
