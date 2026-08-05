# PromptEngine

A powerful Rails engine for managing AI prompts with version control, A/B testing, and seamless LLM
integration. PromptEngine provides a centralized admin interface where teams can create, version,
test, and optimize their AI prompts without deploying code changes.

[![Made with ❤️ by Avi.nyc](https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F%20by-Avi.nyc-ff69b4)](https://avi.nyc)
[![Sponsored by Innovent Capital](https://img.shields.io/badge/Sponsored%20by-Innovent%20Capital-blue)](https://innoventcapital.com)

## WARNING - IN ACTIVE DEVELOPMENT

PromptEngine is currently being worked on actively to prepare for a proper initial version release. You can use it by including the gem sourced from the main branch of this repo however **as we make changes, we will not ensure backward compatibility.** Use at your own risk for now, but a final version should be ready in the next week.

## Documentation and Demo

- 🚀 [Live Demo App](https://prompt-engine-demo.avi.nyc)

## Why PromptEngine?

- **Version Control**: Track every change to your prompts with automatic versioning
- **A/B Testing**: Test different prompt variations with built-in evaluation tools
- **No Deploy Required**: Update prompts through the admin UI without code changes
- **LLM Agnostic**: Works with OpenAI, Anthropic, and other providers
- **Type Safety**: Automatic parameter detection and validation
- **Team Collaboration**: Centralized prompt management for your entire team
- **Production Ready**: Battle-tested with secure API key storage

## Features

- 🎯 **Smart Prompt Management**: Create and organize prompts with slug-based identification
- 📝 **Version Control**: Automatic versioning with one-click rollback
- 🔍 **Variable Detection**: Auto-detects `{{variables}}` and creates typed parameters
- 🧪 **Playground**: Test prompts with real AI providers before deploying
- 🔐 **Secure**: Encrypted API key storage using Rails encryption
- 🚀 **Modern API**: Object-oriented design with direct LLM integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_engine"
```

```sh
bundle add "prompt_engine"
```

And then execute:

```bash
$ bundle

# IMPORTANT: You must install migrations before running db:migrate
$ rails prompt_engine:install:migrations
$ rails db:migrate
$ rails prompt_engine:seed  # Optional: adds sample prompts
```

**Note**: PromptEngine migrations are NOT automatically loaded. You must explicitly run `rails prompt_engine:install:migrations` before running `rails db:migrate`.

## Mount the Engine

In your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"
  # your other routes...
end
```

### Authentication (Recommended for Production)

PromptEngine provides flexible authentication options to secure your admin interface. Since prompt templates may contain sensitive business logic, we strongly recommend configuring authentication for production environments.

#### Option 1: Route-level Authentication (Devise)

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount PromptEngine::Engine => "/prompt_engine"
end
```

#### Option 2: Basic Authentication

```ruby
# config/initializers/prompt_engine.rb
PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_username, username
  ) & ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_password, password
  )
end
```

#### Option 3: Custom Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_admin!
  
  private
  
  def authenticate_admin!
    redirect_to main_app.root_path unless current_user&.admin?
  end
  
  def current_user
    # Your app's current user method
    main_app.current_user
  end
end
```

#### Rails 8 Authentication

If using Rails 8's built-in authentication generator:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  include Authentication # Rails 8's authentication concern
  before_action :require_authentication
end
```

## Admin Interface

Visit `/prompt_engine` in your browser to access the admin interface where you can:

- Create and manage prompts
- Test prompts in the playground
- View version history
- Monitor prompt performance

### In Your Application

```ruby
# Render a prompt with variables (defaults to active prompts only)
rendered = PromptEngine.render("customer-support",
  { customer_name: "John", issue: "Can't login to my account" }
)

# Access rendered content
rendered.content         # => "Hello John, I understand you're having trouble..."
rendered.system_message  # => "You are a helpful customer support agent..."
rendered.model          # => "gpt-4"
rendered.temperature    # => 0.7

# Access parameter values - see docs/VARIABLE_ACCESS.md for details
rendered.parameters      # => {"customer_name" => "John", "issue" => "Can't login..."}
rendered.parameter(:customer_name)  # => "John"

# Direct integration with OpenAI
client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
response = rendered.execute_with(client)

# Or with Anthropic
client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
response = rendered.execute_with(client)

# Override model settings at runtime
rendered = PromptEngine.render("email-writer",
  { subject: "Welcome to our platform" },
  options: { model: "gpt-4-turbo", temperature: 0.9 }
)

# Load a specific version
rendered = PromptEngine.render("onboarding-email",
  { user_name: "Sarah" },
  options: { version: 3 }
)

# Render prompts with different statuses (defaults to 'active')
# Useful for testing drafts or accessing archived prompts
rendered = PromptEngine.render("new-feature",
  { feature_name: "AI Assistant" },
  options: { status: "draft" }  # Can be 'draft', 'active', or 'archived'
)
```

## How It Works

1. **Create Prompts**: Use the admin UI to create prompts with `{{variables}}`
2. **Auto-Detection**: PromptEngine automatically detects variables and creates parameters
3. **Version Control**: Every save creates a new version automatically
4. **Test & Deploy**: Test in the playground, then use in your application
5. **Monitor**: Track usage and performance through the dashboard

## API Documentation

### PromptEngine.render(slug, variables = {}, options: {})

Renders a prompt template with the given variables.

**Parameters:**

- `slug` (String): The unique identifier for the prompt
- `variables` (Hash): Variables to interpolate in the prompt (optional positional argument)
- `options:` (Hash): Rendering options (optional keyword argument)
  - `status`: The status to filter by (defaults to 'active')
  - `model`: Override the default model
  - `temperature`: Override the default temperature
  - `max_tokens`: Override the default max tokens
  - `version`: Load a specific version number

**Returns:** `PromptEngine::RenderedPrompt` instance

### RenderedPrompt Methods

- `content`: The rendered prompt content
- `system_message`: The system message (if any)
- `model`: The AI model to use
- `temperature`: The temperature setting
- `max_tokens`: The max tokens setting
- `to_openai_params`: Convert to OpenAI API format
- `to_ruby_llm_params`: Convert to RubyLLM/Anthropic format
- `execute_with(client)`: Execute with an LLM client

## Contributing

We welcome contributions! Here's how you can help:

### Development Setup

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/prompt_engine.git
   cd prompt_engine
   ```

3. Install dependencies:

   ```bash
   bundle install
   ```

4. Run setup script

   ```bash
   bundle exec rails setup
   ```

5. Run the tests:

   ```bash
   bundle exec rspec
   ```

6. Start the development server:
   ```bash
   bundle exec rails server
   ```

### Making Changes

1. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and ensure tests pass:

   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```

3. Commit your changes:

   ```bash
   git commit -m "Add your feature"
   ```

4. Push to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

5. Create a Pull Request

### Guidelines

- Write tests for new features
- Follow Rails best practices
- Use conventional commit messages
- Update documentation as needed
- Be respectful in discussions

## Architecture

PromptEngine follows Rails engine conventions with a modular architecture:

- **Models**: Prompt, PromptVersion, Parameter, EvalSet, TestCase
- **Services**: VariableDetector, PlaygroundExecutor, PromptRenderer
- **Admin UI**: Built with Hotwire, Stimulus, and Turbo
- **API**: Object-oriented design with RenderedPrompt instances

## Roadmap
- [ ] Proper Eval Sandbox and Testing
- [ ] Logging and Observability of Prompt Usage
- [ ] Cost tracking and optimization

## Sponsors

- [Innovent Capital](https://innoventcapital.com) - _Pioneering AI innovation in financial services_

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Support

- 🚀 [Live Demo App](https://prompt-engine-demo.avi.nyc)
- 📖 [Documentation](https://prompt-engine-docs.avi.nyc/)
- 🐛 [Issue Tracker](https://github.com/aviflombaum/prompt_engine/issues)
- 💬 [Discussions](https://github.com/aviflombaum/prompt_engine/discussions)
- 📧 [Email Support](mailto:ruby@avi.nyc)

---

Built with ❤️ by [Avi.nyc](https://avi.nyc)
