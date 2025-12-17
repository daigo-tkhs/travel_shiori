# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# その他、必要なライブラリ
pin "sortablejs" 
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js"
pin "debounce"

# ▼▼▼ 強制的に読み込ませるための明示的な指定 ▼▼▼
pin "controllers/map_controller", to: "controllers/map_controller.js"
pin "controllers/sortable_controller", to: "controllers/sortable_controller.js"
pin "controllers/geocoding_controller", to: "controllers/geocoding_controller.js"