# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# ポイント: to: の指定で必ず ".js" を付けること
pin "controllers/map_controller", to: "controllers/map_controller.js"
pin "controllers/sortable_controller", to: "controllers/sortable_controller.js"
pin "controllers/geocoding_controller", to: "controllers/geocoding_controller.js"

# その他
pin "sortablejs" 
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js"
pin "debounce"