class MigrateUsersToTable < ActiveRecord::Migration
  def up
    puts "Populate User model"
    values = RunCommand.select(:user_id, :user_name).distinct.map do |c|
        u = User.new(user_id: c.user_id, user_name: c.user_name)
        u.save!
    end

    puts "Add FKs to Pin author, pinner"
    change_table :pins do |t|
        t.rename :author_id, :author_slack_id
        t.rename :pinner_id, :pinner_slack_id
        t.remove :author_name
        t.remove :pinner_name
        t.references :author, references: :users, index: true, on_delete: :nullify
        t.references :pinner, references: :users, index: true, on_delete: :nullify
    end

    puts "Set user id references"
    Pin.all.each do |p|
        author = User.with_user_id(p.author_slack_id).first
        pinner = User.with_user_id(p.pinner_slack_id).first
        puts "Pin #{p.text} by author #{author} pinned by #{pinner}"
        p.author = author
        p.pinner = pinner
        p.save!
    end

    change_table :pins do |t|
        t.remove :author_slack_id
        t.remove :pinner_slack_id
    end

    puts "Add FK to RunCommand user"
    change_table :run_commands do |t|
        t.rename :user_id, :user_slack_id
        t.remove :user_name
        t.references :user, index: true, on_delete: :nullify
    end

    puts "Set user id references"
    RunCommand.all.map do |c|
        user = User.with_user_id(c.user_slack_id).first
        c.user = user
        c.save!
    end

    remove_column :run_commands, :user_slack_id

    puts "Add FK to UserPrivilege"
    change_table :user_privileges do |t|
        t.rename :user_id, :user_slack_id
        t.remove :user_name
        t.references :user, index: true, on_delete: :cascade
    end

    puts "Set user id references"
    UserPrivilege.all.each do |c|
        c.user_id
        user = User.with_user_id(c.user_slack_id).first
        c.user = user
        c.save!
    end

    remove_column :user_privileges, :user_slack_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
