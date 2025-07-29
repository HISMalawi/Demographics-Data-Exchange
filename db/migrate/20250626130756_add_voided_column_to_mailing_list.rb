class AddVoidedColumnToMailingList < ActiveRecord::Migration[7.0]
   if ENV['MASTER'] == 'true'
    def change
      add_column :mailing_lists, :voided, :boolean, default: false
    end
  end
end
