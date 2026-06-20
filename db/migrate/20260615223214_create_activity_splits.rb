class CreateActivitySplits < ActiveRecord::Migration[7.2]
  def change
    create_table :activity_splits do |t|
      t.references :activity, null: false, foreign_key: true
      t.integer  :split_index,          null: false
      t.float    :distance,             null: false
      t.integer  :moving_time,          null: false
      t.integer  :elapsed_time,         null: false
      t.float    :average_speed,        null: false
      t.float    :elevation_difference

      t.timestamps
    end

    add_index :activity_splits, [ :activity_id, :split_index ], unique: true
  end
end
