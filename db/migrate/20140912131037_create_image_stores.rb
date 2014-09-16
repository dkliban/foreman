class CreateImageStores < ActiveRecord::Migration
  def self.up
    create_table :image_stores do |t|
      t.string :name
      t.string :description
      t.string :url
      t.string :uuid
      t.string :type
      t.string :cert

      t.timestamps
    end
  end

  def self.down
    drop_table :image_stores
  end
end
