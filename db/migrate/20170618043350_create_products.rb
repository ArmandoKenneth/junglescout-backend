class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.string :asin
      t.string :title
      t.float :rating
      t.string :review_url
      t.timestamp :review_valid_until

      t.timestamps
    end
  end
end
