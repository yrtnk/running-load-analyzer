class AddLoadFieldsToActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :activities, :load_score, :float
    add_column :activities, :load_category, :string
  end
end
