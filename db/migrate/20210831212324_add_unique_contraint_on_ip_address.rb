class AddUniqueContraintOnIpAddress < ActiveRecord::Migration[5.2]
  def change
    add_index :locations, :ip_address, unique: true
  end
end
