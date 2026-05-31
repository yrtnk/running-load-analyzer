class CreateTargetTimes < ActiveRecord::Migration[7.2]
  def change
    create_table :target_times do |t|
      t.references :user,                 null: false, foreign_key: true
      t.integer    :target_marathon_time, null: false
      t.float      :target_vdot,          null: false
      t.date       :revised_at,           null: false

      t.timestamps
    end

    add_index :target_times, [ :user_id, :revised_at ], unique: true
  end
end
