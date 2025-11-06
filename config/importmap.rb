# Pin npm packages by running ./bin/importmap

pin "@hotwired/turbo-rails", to: "turbo.js"
pin "@hotwired/turbo", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.js"
pin "application"
pin "services"
pin "footprint_stats"


pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
