# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# ▼ これをコメントアウトします
# pin_all_from "app/javascript/controllers", under: "controllers"

# ▼ 個別に手動でピン留めします（.jsを明示し、ハッシュ化に対応させる）
pin "controllers/application", to: "controllers/application.js"
pin "controllers/hello_controller", to: "controllers/hello_controller.js"
pin "controllers/index", to: "controllers/index.js"
pin "controllers/map_controller", to: "controllers/map_controller.js"
pin "controllers/sortable_controller", to: "controllers/sortable_controller.js"
pin "controllers/geocoding_controller", to: "controllers/geocoding_controller.js"
pin "controllers/scroll_controller", to: "controllers/scroll_controller.js"

# その他のライブラリ
pin "sortablejs" 
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js"
pin "debounce"
pin "@hotwired/turbo", to: "@hotwired--turbo.js"