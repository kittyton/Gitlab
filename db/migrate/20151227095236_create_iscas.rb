class CreateIscas < ActiveRecord::Migration
  def change
    create_table :iscas do |t|
      t.integer :member_id
      t.timestamps
    end
  end
end
