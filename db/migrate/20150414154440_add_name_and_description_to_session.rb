class AddNameAndDescriptionToSession < ActiveRecord::Migration
  def change
    add_column :sessions, :name, :string
    add_column :sessions, :description, :text
  end
end
