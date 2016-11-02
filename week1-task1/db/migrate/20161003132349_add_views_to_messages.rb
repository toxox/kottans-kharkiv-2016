class AddViewsToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :should_destroy_after_view, :boolean
    add_column :messages, :views_left, :integer
  end
end
