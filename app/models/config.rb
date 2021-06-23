class Config < ApplicationRecord
    validates_presence_of :config,
    :config_value,:description,:uuid,
    :created_at,:updated_at
end
