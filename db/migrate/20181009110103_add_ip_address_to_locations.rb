class AddIpAddressToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :ip_address, :string
  end    
end