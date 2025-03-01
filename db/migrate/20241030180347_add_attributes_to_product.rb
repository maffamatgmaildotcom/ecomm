class AddAttributesToProduct < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :item_number, :string
    add_column :products, :year_issued, :string
    add_column :products, :year_retired, :string
    add_column :products, :usd_srp, :integer
    add_column :products, :cad_srp, :integer
    add_column :products, :owned, :boolean, default: false
  end
end
