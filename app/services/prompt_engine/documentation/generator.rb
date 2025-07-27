require "ruby_llm"

module PromptEngine
  module Documentation
    class Generator
      attr_reader :output_dir, :llm_client

      def initialize(output_dir: "docs/site")
        @output_dir = output_dir
        @llm_client = initialize_llm_client
      end

      def generate_all
        ensure_output_directory
        
        generate_index_page
        generate_getting_started
        generate_installation
        generate_configuration
        
        generate_model_docs
        generate_controller_docs
        generate_service_docs
        generate_guide_docs
        generate_reference_docs
      end

      def generate_model_docs
        ensure_directory("#{output_dir}/api/models")
        
        model_files = Dir.glob("app/models/prompt_engine/**/*.rb")
        
        # Generate index page for models
        generate_models_index(model_files)
        
        # Generate individual model pages
        model_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          
          doc_content = generate_model_documentation(analysis)
          filename = analysis[:class_name].underscore.dasherize
          write_documentation("api/models/#{filename}.md", doc_content)
        end
      end

      def generate_controller_docs
        ensure_directory("#{output_dir}/api/controllers")
        
        controller_files = Dir.glob("app/controllers/prompt_engine/**/*.rb")
        
        # Generate index page for controllers
        generate_controllers_index(controller_files)
        
        # Generate individual controller pages
        controller_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          
          doc_content = generate_controller_documentation(analysis)
          filename = analysis[:class_name].underscore.dasherize.gsub("-controller", "")
          write_documentation("api/controllers/#{filename}.md", doc_content)
        end
      end

      def generate_service_docs
        ensure_directory("#{output_dir}/api/services")
        
        service_files = Dir.glob("app/services/prompt_engine/**/*.rb")
        
        # Generate index page for services
        generate_services_index(service_files)
        
        # Generate individual service pages
        service_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          next if analysis[:class_name] == "CodeAnalyzer" || analysis[:class_name] == "Generator"
          
          doc_content = generate_service_documentation(analysis)
          filename = analysis[:class_name].underscore.dasherize
          write_documentation("api/services/#{filename}.md", doc_content)
        end
      end

      private

      def initialize_llm_client
        # Try Anthropic first, fall back to OpenAI
        # In a Rails engine context, we need to check if we're in dummy app or host app
        app = defined?(Rails.application) ? Rails.application : nil
        
        if app && app.credentials.dig(:anthropic, :api_key)
          RubyLLM::Anthropic.new(
            api_key: app.credentials.anthropic[:api_key],
            model: "claude-3-5-sonnet-20241022"
          )
        elsif app && app.credentials.dig(:openai, :api_key)
          RubyLLM::OpenAI.new(
            api_key: app.credentials.openai[:api_key],
            model: "gpt-4-turbo"
          )
        elsif ENV["ANTHROPIC_API_KEY"]
          RubyLLM::Anthropic.new(
            api_key: ENV["ANTHROPIC_API_KEY"],
            model: "claude-3-5-sonnet-20241022"
          )
        elsif ENV["OPENAI_API_KEY"]
          RubyLLM::OpenAI.new(
            api_key: ENV["OPENAI_API_KEY"],
            model: "gpt-4-turbo"
          )
        else
          # Return nil to allow mock mode
          nil
        end
      end

      def ensure_output_directory
        FileUtils.mkdir_p(output_dir)
      end

      def ensure_directory(path)
        FileUtils.mkdir_p(path)
      end

      def generate_model_documentation(analysis)
        prompt = build_model_prompt(analysis)
        
        response = llm_client.complete(prompt)
        content = response.completion
        
        # Add frontmatter
        frontmatter = {
          title: analysis[:class_name].titleize,
          layout: "docs",
          parent: "api/models",
          nav_order: analysis[:class_name].downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def generate_controller_documentation(analysis)
        prompt = build_controller_prompt(analysis)
        
        response = llm_client.complete(prompt)
        content = response.completion
        
        # Add frontmatter
        controller_name = analysis[:class_name].gsub("Controller", "")
        frontmatter = {
          title: "#{controller_name} API",
          layout: "docs",
          parent: "api/controllers",
          nav_order: controller_name.downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def generate_service_documentation(analysis)
        prompt = build_service_prompt(analysis)
        
        response = llm_client.complete(prompt)
        content = response.completion
        
        # Add frontmatter
        frontmatter = {
          title: analysis[:class_name].titleize,
          layout: "docs",
          parent: "api/services",
          nav_order: analysis[:class_name].downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def build_model_prompt(analysis)
        <<~PROMPT
          You are a technical writer creating documentation for a Rails model.

          Given this Ruby model code:
          #{analysis[:raw_content]}

          Model Analysis:
          - Class: #{analysis[:class_name]}
          - Module: #{analysis[:module_name]}
          - Associations: #{analysis[:associations].to_json}
          - Validations: #{analysis[:validations].to_json}
          - Attributes: #{analysis[:attributes].to_json}
          - Methods: #{analysis[:methods].map { |m| m[:name] }.join(", ")}

          Generate comprehensive markdown documentation including:
          1. A brief description of the model's purpose
          2. Table of attributes with types and descriptions
          3. List of associations with explanations
          4. List of validations with business rules
          5. Key methods with usage examples
          6. Common usage patterns
          7. Any important notes or caveats

          Format the output as clean, readable markdown. Do not include frontmatter.
        PROMPT
      end

      def build_controller_prompt(analysis)
        <<~PROMPT
          You are a technical writer creating API documentation.

          Given this Rails controller code:
          #{analysis[:raw_content]}

          Controller Analysis:
          - Class: #{analysis[:class_name]}
          - Module: #{analysis[:module_name]}
          - Methods: #{analysis[:methods].to_json}

          Generate API documentation including:
          1. Brief description of the controller's purpose
          2. For each action:
             - HTTP method and path
             - Description
             - Parameters (required/optional)
             - Response format
             - Status codes
             - Example request/response
          3. Authentication requirements
          4. Error handling

          Format as clean markdown with clear examples. Do not include frontmatter.
        PROMPT
      end

      def build_service_prompt(analysis)
        <<~PROMPT
          You are a technical writer documenting a service object.

          Given this service class:
          #{analysis[:raw_content]}

          Service Analysis:
          - Class: #{analysis[:class_name]}
          - Module: #{analysis[:module_name]}
          - Methods: #{analysis[:methods].to_json}

          Generate documentation including:
          1. Purpose and responsibility
          2. Usage examples
          3. Method documentation
          4. Error scenarios
          5. Best practices

          Format as clean, readable markdown. Do not include frontmatter.
        PROMPT
      end

      def add_frontmatter(content, metadata)
        frontmatter = metadata.map { |k, v| "#{k}: #{v.to_s.inspect}" }.join("\n")
        
        <<~DOC
          ---
          #{frontmatter}
          ---

          #{content}
        DOC
      end

      def write_documentation(relative_path, content)
        full_path = File.join(output_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
        puts "Generated: #{relative_path}"
      end

      def generate_index_page
        content = <<~MD
          ---
          title: "PromptEngine Documentation"
          layout: "docs"
          nav_order: 1
          ---

          # PromptEngine Documentation

          Welcome to the PromptEngine documentation. PromptEngine is a Rails engine for managing AI prompts with version control, testing, and optimization features.

          ## Quick Links

          - [Getting Started](getting-started.md) - Quick setup guide
          - [Installation](installation.md) - Detailed installation instructions
          - [Configuration](configuration.md) - Configuration options
          - [API Reference](api/) - Complete API documentation
          - [Guides](guides/) - How-to guides and tutorials

          ## Features

          - **Prompt Management**: Create and organize AI prompts with variable support
          - **Version Control**: Automatic versioning with full history
          - **Testing Playground**: Test prompts with real AI providers
          - **Parameter Validation**: Type-safe variable handling
          - **Admin Interface**: User-friendly web UI for prompt management

          ## Architecture

          PromptEngine follows Rails conventions and is designed as a mountable engine that integrates seamlessly with your Rails application.
        MD

        write_documentation("index.md", content)
      end

      def generate_getting_started
        content = <<~MD
          ---
          title: "Getting Started"
          layout: "docs"
          nav_order: 2
          ---

          # Getting Started with PromptEngine

          This guide will help you get PromptEngine up and running quickly.

          ## Prerequisites

          - Ruby 3.0+
          - Rails 8.0.2+
          - PostgreSQL or MySQL database

          ## Quick Setup

          1. Add PromptEngine to your Gemfile:

          ```ruby
          gem 'prompt_engine'
          ```

          2. Install the gem:

          ```bash
          bundle install
          ```

          3. Mount the engine in your routes:

          ```ruby
          # config/routes.rb
          Rails.application.routes.draw do
            mount PromptEngine::Engine => "/prompt_engine"
          end
          ```

          4. Install migrations:

          ```bash
          bin/rails prompt_engine:install:migrations
          bin/rails db:migrate
          ```

          5. Configure API credentials:

          ```bash
          rails credentials:edit
          ```

          Add your API keys:

          ```yaml
          openai:
            api_key: sk-your-openai-key
          anthropic:
            api_key: sk-ant-your-anthropic-key
          ```

          6. Start your Rails server and visit `/prompt_engine`

          ## Next Steps

          - [Create your first prompt](guides/basic-usage.md)
          - [Configure advanced settings](configuration.md)
          - [Explore the API](api/)
        MD

        write_documentation("getting-started.md", content)
      end

      def generate_installation
        # Read the actual README for installation details
        readme_path = Rails.root.join("README.md")
        readme_content = File.exist?(readme_path) ? File.read(readme_path) : ""
        
        prompt = <<~PROMPT
          Based on this README content:
          #{readme_content}

          Generate a detailed installation guide for PromptEngine in markdown format.
          Include:
          1. System requirements
          2. Step-by-step installation
          3. Database setup
          4. Configuration options
          5. Troubleshooting common issues
          
          Format as clean markdown. Do not include frontmatter.
        PROMPT

        response = llm_client.complete(prompt)
        content = response.completion

        frontmatter = {
          title: "Installation",
          layout: "docs",
          nav_order: 3
        }

        write_documentation("installation.md", add_frontmatter(content, frontmatter))
      end

      def generate_configuration
        content = <<~MD
          ---
          title: "Configuration"
          layout: "docs"
          nav_order: 4
          ---

          # Configuration

          PromptEngine can be configured through Rails credentials and initializers.

          ## API Credentials

          Configure your AI provider credentials:

          ```bash
          rails credentials:edit
          ```

          ```yaml
          # Required: At least one provider
          openai:
            api_key: sk-your-openai-key
            
          anthropic:
            api_key: sk-ant-your-anthropic-key
          ```

          ## Initializer Options

          Create an initializer for advanced configuration:

          ```ruby
          # config/initializers/prompt_engine.rb
          PromptEngine.configure do |config|
            # Default model for playground
            config.default_model = "gpt-4"
            
            # Enable/disable features
            config.enable_playground = true
            config.enable_analytics = false
            
            # Security
            config.require_authentication = true
            config.admin_role = :admin
          end
          ```

          ## Environment Variables

          Supported environment variables:

          - `PROMPT_ENGINE_API_TIMEOUT` - API request timeout (default: 30)
          - `PROMPT_ENGINE_MAX_TOKENS` - Maximum tokens per request (default: 4000)
          - `PROMPT_ENGINE_CACHE_ENABLED` - Enable response caching (default: false)

          ## Database Configuration

          PromptEngine works with PostgreSQL and MySQL. Ensure your database supports:

          - JSON columns (for model_config)
          - Full-text search (optional, for better search)
          - UUID support (optional, for better IDs)
        MD

        write_documentation("configuration.md", content)
      end

      def generate_models_index(model_files)
        content = <<~MD
          ---
          title: "Models"
          layout: "docs"
          parent: "api"
          nav_order: 1
          has_children: true
          ---

          # Model Documentation

          PromptEngine includes the following models:

        MD

        model_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          
          filename = analysis[:class_name].underscore.dasherize
          content += "- [#{analysis[:class_name]}](#{filename}.md) - #{describe_model(analysis[:class_name])}\n"
        end

        write_documentation("api/models/index.md", content)
      end

      def generate_controllers_index(controller_files)
        content = <<~MD
          ---
          title: "Controllers"
          layout: "docs"
          parent: "api"
          nav_order: 2
          has_children: true
          ---

          # Controller Documentation

          API endpoints provided by PromptEngine:

        MD

        controller_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          
          controller_name = analysis[:class_name].gsub("Controller", "")
          filename = controller_name.underscore.dasherize
          content += "- [#{controller_name} API](#{filename}.md)\n"
        end

        write_documentation("api/controllers/index.md", content)
      end

      def generate_services_index(service_files)
        content = <<~MD
          ---
          title: "Services"
          layout: "docs"
          parent: "api"
          nav_order: 3
          has_children: true
          ---

          # Service Documentation

          Service objects used internally by PromptEngine:

        MD

        service_files.each do |file|
          analysis = CodeAnalyzer.new(file).analyze
          next unless analysis[:class_name]
          next if analysis[:class_name] == "CodeAnalyzer" || analysis[:class_name] == "Generator"
          
          filename = analysis[:class_name].underscore.dasherize
          content += "- [#{analysis[:class_name]}](#{filename}.md)\n"
        end

        write_documentation("api/services/index.md", content)
      end

      def generate_guide_docs
        ensure_directory("#{output_dir}/guides")
        
        # Generate guides index and basic guides
        # This would analyze existing docs and examples to generate guides
      end

      def generate_reference_docs
        ensure_directory("#{output_dir}/reference")
        
        # Generate reference documentation
        # This would include rake tasks, configuration reference, etc.
      end

      def describe_model(class_name)
        case class_name
        when "Prompt"
          "Core prompt model with version control"
        when "PromptVersion"
          "Immutable prompt snapshots"
        when "Parameter"
          "Variable definitions and validation"
        else
          "#{class_name} model"
        end
      end
    end
  end
end