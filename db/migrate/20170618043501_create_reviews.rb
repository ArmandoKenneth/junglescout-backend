class CreateReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :reviews do |t|
      t.string :reviewer
      t.string :title
      t.date :date
      t.float :rating
      t.string :review
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
