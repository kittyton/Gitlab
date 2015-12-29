class AddTaskIdToWebHooks < ActiveRecord::Migration
  def change
    add_column :web_hooks, :task_id, :integer
  end
end
