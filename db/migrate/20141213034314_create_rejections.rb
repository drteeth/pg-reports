class CreateRejections < ActiveRecord::Migration
  def change
    create_table :rejections do |t|
      t.references :post, index: true
      t.integer :reason

      t.timestamps
    end
  end
end
