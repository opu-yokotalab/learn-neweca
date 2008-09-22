class CreateEngines < ActiveRecord::Migration
  def self.up
    create_table :engines do |t|
      t.string :name
      t.string :rule

      t.timestamps
    end
  end

  def self.down
    drop_table :engines
  end
end
