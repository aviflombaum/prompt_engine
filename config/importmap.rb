# Pin npm packages by running ./bin/importmap

pin "prompt_engine/application", to: "prompt_engine/application.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Pin all Stimulus controllers
pin_all_from PromptEngine::Engine.root.join("app/javascript/prompt_engine/controllers"), under: "prompt_engine/controllers"