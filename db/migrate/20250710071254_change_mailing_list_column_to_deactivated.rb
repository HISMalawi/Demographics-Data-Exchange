class ChangeMailingListColumnToDeactivated < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      rename_column :mailing_lists, :voided, :deactivated
    end
  end
end
