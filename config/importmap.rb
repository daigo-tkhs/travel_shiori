# config/importmap.rb

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.20
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# その他のライブラリ
pin "sortablejs" 
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.1.100
pin "debounce"
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.20