class CreateActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint  :strava_activity_id, null: false
      t.string  :name, null: false
      t.float   :distance
      t.integer :moving_time
      t.integer :elapsed_time
      t.float   :average_heartrate
      t.integer :max_heartrate
      t.float   :average_pace
      t.datetime :start_date
      t.string  :activity_type

      t.timestamps
    end

    add_index :activities, %i[user_id strava_activity_id], unique: true
  end
end
