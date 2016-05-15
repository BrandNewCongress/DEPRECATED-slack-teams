class CreateEvent < ActiveRecord::Migration
  def up
  	create_table :events do |e|
  		e.string :title
  		e.string :spreadsheet_key
  		e.string :form_key
  	end
  end

  def down
  	drop_table :events
  end
end
