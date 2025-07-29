# PromptEngine

A powerful Rails engine for managing AI prompts with version control, A/B testing, and seamless LLM
integration. PromptEngine provides a centralized admin interface where teams can create, version,
test, and optimize their AI prompts without deploying code changes.

[![Made with ❤️ by Avi.nyc](https://img.shields.io/badge/Made%20with%20%E2%9D%A4%EF%B8%8F%20by-Avi.nyc-ff69b4)](https://avi.nyc)
[![Sponsored by Innovent Capital](https://img.shields.io/badge/Sponsored%20by-Innovent%20Capital-blue)](https://innoventcapital.com)

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
- 📊 **Evaluation Suite**: Create test cases and measure prompt performance
- 🔐 **Secure**: Encrypted API key storage using Rails encryption
- 🚀 **Modern API**: Object-oriented design with direct LLM integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_engine"
```

And then execute:

```bash
$ bundle
$ rails prompt_engine:install:migrations
$ rails db:migrate
$ rails prompt_engine:seed  # Optional: adds sample prompts
```

For migration handling details, see [docs/MIGRATIONS.md](docs/MIGRATIONS.md).

## Setup

### 1. Configure Encryption

PromptEngine uses Rails encryption to secure API keys. For detailed setup instructions, see [docs/ENCRYPTION_SETUP.md](docs/ENCRYPTION_SETUP.md).

**Quick start for development:**

```ruby
# config/environments/development.rb
config.active_record.encryption.primary_key = 'development' * 4
config.active_record.encryption.deterministic_key = 'development' * 4
config.active_record.encryption.key_derivation_salt = 'development' * 4
```

For production, use `rails db:encryption:init` to generate secure keys.

### 2. Configure API Keys

Add your AI provider API keys to Rails credentials. See [docs/API_CREDENTIALS.md](docs/API_CREDENTIALS.md) for complete configuration options.

```bash
rails credentials:edit
```

```yaml
openai:
  api_key: sk-your-openai-api-key
anthropic:
  api_key: sk-ant-your-anthropic-api-key
```

### 3. Mount the Engine

In your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"
  # your other routes...
end
```

### 4. Authentication (Optional but Recommended)

PromptEngine provides flexible authentication options to secure your admin interface. By default, authentication is enabled but not configured, allowing full access. We strongly recommend configuring authentication for production environments.

#### Quick Start

The simplest way to secure PromptEngine is with HTTP Basic authentication:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = "admin"
  config.http_basic_auth_password = "secure_password_here"
end
```

For production, use Rails credentials:

```bash
rails credentials:edit
```

```yaml
# Add to credentials file
prompt_engine:
  username: your_secure_username
  password: your_secure_password
```

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = Rails.application.credentials.dig(:prompt_engine, :username)
  config.http_basic_auth_password = Rails.application.credentials.dig(:prompt_engine, :password)
end
```

#### Authentication Strategies

##### 1. HTTP Basic Authentication

Built-in support with secure credential comparison:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.authentication_enabled = true  # Default: true
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = ENV['PROMPT_ENGINE_USERNAME']
  config.http_basic_auth_password = ENV['PROMPT_ENGINE_PASSWORD']
end
```

**Security Notes:**
- Uses `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks
- Credentials are never logged or exposed in errors
- Empty credentials are treated as invalid

##### 2. Devise Integration

For Devise authentication, mount the engine within an authenticated route:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
end
```

##### 3. Custom Authentication

Integrate with your existing authentication system using the ActiveSupport hook:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action do
    raise ActionController::RoutingError.new('Not Found') unless current_user&.admin?
  end

  def current_user
    # Your authentication logic here
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
```

##### 4. Rack Middleware Authentication

For advanced scenarios, add custom middleware directly to the engine:

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

##### 5. Disable Authentication (Development Only)

⚠️ **Warning:** Only disable authentication in development environments:

```ruby
# config/initializers/prompt_engine.rb
if Rails.env.development?
  PromptEngine.configure do |config|
    config.authentication_enabled = false
  end
end
```

#### Configuration Reference

| Setting | Default | Description |
|---------|---------|-------------|
| `authentication_enabled` | `true` | Master switch for all authentication |
| `http_basic_auth_enabled` | `false` | Enable HTTP Basic authentication |
| `http_basic_auth_name` | `nil` | Username for HTTP Basic auth |
| `http_basic_auth_password` | `nil` | Password for HTTP Basic auth |

#### Testing with Authentication

When writing tests, you can disable authentication:

```ruby
# spec/rails_helper.rb or test/test_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    PromptEngine.authentication_enabled = false
  end
end
```

Or provide credentials in your tests:

```ruby
get prompt_engine.prompts_path, headers: {
  "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password")
}
```

#### Security Best Practices

1. **Always enable authentication in production**
2. **Use strong, unique passwords**
3. **Store credentials securely** (Rails credentials, environment variables, or secrets management)
4. **Use HTTPS** to encrypt authentication credentials in transit
5. **Implement rate limiting** on your application server
6. **Monitor access logs** for suspicious activity

For more authentication examples and advanced configurations, see [AUTHENTICATION.md](docs/AUTHENTICATION.md)

## Usage

For detailed usage instructions and examples, see [docs/USAGE.md](docs/USAGE.md).

### Admin Interface

Visit `/prompt_engine` in your browser to access the admin interface where you can:

- Create and manage prompts
- Test prompts in the playground
- View version history
- Create evaluation sets
- Monitor prompt performance

### In Your Application

```ruby
# Render a prompt with variables
rendered = PromptEngine.render("customer-support",
  customer_name: "John",
  issue: "Can't login to my account"
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
  subject: "Welcome to our platform",
  model: "gpt-4-turbo",
  temperature: 0.9
)

# Load a specific version
rendered = PromptEngine.render("onboarding-email",
  user_name: "Sarah",
  version: 3
)
```

For complete parameter access documentation, see [docs/VARIABLE_ACCESS.md](docs/VARIABLE_ACCESS.md).

## How It Works

1. **Create Prompts**: Use the admin UI to create prompts with `{{variables}}`
2. **Auto-Detection**: PromptEngine automatically detects variables and creates parameters
3. **Version Control**: Every save creates a new version automatically
4. **Test & Deploy**: Test in the playground, then use in your application
5. **Monitor**: Track usage and performance through the dashboard

## API Documentation

### PromptEngine.render(slug, \*\*options)

Renders a prompt template with the given variables.

**Parameters:**

- `slug` (String): The unique identifier for the prompt
- `**options` (Hash): Variables and optional overrides
  - Variables: Any key-value pairs matching prompt variables
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

4. Set up the test database:

   ```bash
   cd spec/dummy
   rails db:create db:migrate db:seed
   cd ../..
   ```

5. Run the tests:

   ```bash
   bundle exec rspec
   ```

6. Start the development server:
   ```bash
   cd spec/dummy && rails server
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

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed technical documentation.

## Roadmap

- [ ] Multi-language prompt support
- [ ] Prompt templates marketplace
- [ ] Advanced A/B testing analytics
- [ ] Webhook integrations
- [ ] Prompt chaining
- [ ] Cost tracking and optimization
- [ ] Team collaboration features

## Sponsors

- [Innovent Capital](https://innoventcapital.com) - _Pioneering AI innovation in financial services_

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Documentation

- 📖 [Architecture Overview](docs/ARCHITECTURE.md) - Technical architecture and design decisions
- 🔐 [Authentication Guide](docs/AUTHENTICATION.md) - Securing your PromptEngine installation
- 🔑 [API Credentials Setup](docs/API_CREDENTIALS.md) - Configuring AI provider API keys
- 🔒 [Encryption Setup](docs/ENCRYPTION_SETUP.md) - Setting up Rails encryption for secure storage
- 📦 [Migration Guide](docs/MIGRATIONS.md) - Handling database migrations
- 📝 [Usage Guide](docs/USAGE.md) - Complete usage examples and best practices
- 🔤 [Variable Access](docs/VARIABLE_ACCESS.md) - Working with parameters in rendered prompts
- 📋 [Product Specification](docs/SPEC.md) - Complete product vision and roadmap

## Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/aviflombaum/prompt_engine/issues)
- 💬 [Discussions](https://github.com/aviflombaum/prompt_engine/discussions)
- 📧 [Email Support](mailto:ruby@avi.nyc)

---

Built with ❤️ by [Avi.nyc](https://avi.nyc)
