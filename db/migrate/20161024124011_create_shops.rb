class CreateShops < ActiveRecord::Migration[5.0]
  def change
    create_table :shops do |t|
      t.string :name
      t.string :product_schema_uri
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end
