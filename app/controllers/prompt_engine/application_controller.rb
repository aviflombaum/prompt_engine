module PromptEngine
  class ApplicationController < ActionController::Base
    include PromptEngine::Authentication
    layout "prompt_engine/admin"

    # Run the ActiveSupport hook to allow host app customization
    ActiveSupport.run_load_hooks(:prompt_engine_application_controller, self)
  end
end
