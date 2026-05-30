class AddStravaFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :strava_uid, :string
    add_column :users, :strava_access_token, :string
    add_column :users, :strava_refresh_token, :string
    add_column :users, :strava_token_expires_at, :datetime
    add_index :users, :strava_uid, unique: true
  end
end
