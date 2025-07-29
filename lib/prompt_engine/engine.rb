module PromptEngine
  class Engine < ::Rails::Engine
    isolate_namespace PromptEngine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Ensure services and clients directories are in the autoload paths
    config.autoload_paths += %W[#{config.root}/app/services]
    config.autoload_paths += %W[#{config.root}/app/clients]

    # Configure importmap for the engine
    initializer "prompt_engine.importmap", before: "importmap" do |app|
      # Only configure if the app uses importmap
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end

    # Ensure engine's migrations are available to the host app
    # This is the standard Rails engine pattern
    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    # Define the controller hook for authentication customization
    initializer "prompt_engine.controller_hook" do
      ActiveSupport.on_load(:prompt_engine_application_controller) do
        # This hook allows host applications to add authentication
        # and other controller-level customizations
      end
    end

    # Allow middleware to be added for authentication
    # Example: PromptEngine::Engine.middleware.use(Rack::Auth::Basic) { ... }
  end
end
