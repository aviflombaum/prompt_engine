# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## PromptEngine Rails Engine

PromptEngine is a mountable Rails engine for AI prompt management. It provides a centralized admin
interface where teams can create, version, test, and optimize their AI prompts without deploying
code changes.

## Development Commands

### Initial Setup

```bash
bundle install
bundle exec rake setup                      # Complete setup for development and testing
```

This setup task:
- Removes existing migrations and databases
- Installs engine migrations into dummy app
- Creates and migrates both development and test databases
- Seeds development database with sample data

### Running the Development Server

```bash
cd spec/dummy && rails s
```

Access the admin interface at `http://localhost:3000/prompt_engine`

### Manual Database Setup (if needed)

```bash
cd spec/dummy
bundle exec rails prompt_engine:install:migrations  # Install engine migrations
bundle exec rails db:create db:migrate db:seed      # Setup development database
RAILS_ENV=test bundle exec rails db:create db:migrate  # Setup test database
```

### Running Tests

```bash
bundle exec rspec                           # Run all tests with coverage
bundle exec rspec spec/models               # Run model tests
bundle exec rspec spec/requests             # Run request specs (controllers)
bundle exec rspec spec/system               # Run system tests
bundle exec rspec path/to/spec.rb           # Run specific test file
bundle exec rspec path/to/spec.rb:42        # Run specific test by line number
bundle exec rspec --format documentation    # Run with detailed output
bundle exec rspec --fail-fast              # Stop on first failure

# Coverage report
open coverage/index.html                    # View SimpleCov coverage report
```

### Linting

```bash
bundle exec rubocop                         # Run RuboCop with Rails Omakase style
bundle exec rubocop -a                      # Auto-correct offenses
```

### Rake Tasks

```bash
bundle exec rake setup                      # Setup dummy app for development
bundle exec rake spec                       # Run all specs
bundle exec rake prompt_engine:setup        # Alternative setup command
bin/rails prompt_engine:install:migrations  # Install engine migrations in host app
```

## Architecture Overview

### Core Models & Relationships

**PromptEngine::Prompt**

- Central model containing prompt templates with `{{variable}}` syntax
- Has many versions (auto-versioned on content/system_message changes)
- Has many parameters (auto-detected from variables)
- Status enum: draft, active, archived
- Key method: `render(variables: {})` for template rendering

**PromptEngine::PromptVersion**

- Immutable snapshots of prompts
- Auto-incremented version numbers
- Stores content, system_message, model_config at time of creation
- Key method: `restore!` to revert prompt to this version

**PromptEngine::Parameter**

- Defines expected variables with types and validation
- Types: string, integer, decimal, boolean, datetime, date, array, json
- Auto-generates appropriate form inputs

### Service Objects

**VariableDetector**

- Extracts `{{variables}}` from prompt content
- Infers types from variable names (e.g., `_at` → datetime)
- Validates provided variables against template

**PlaygroundExecutor**

- Handles AI provider communication (Anthropic, OpenAI)
- Manages API keys from Rails credentials
- Formats requests and parses responses
- Supports PDF file attachments for document-based prompts

### Testing Philosophy

Read `.ai/RSPEC-TESTS.md` before writing tests. Key principles:

- Use request specs instead of controller specs for testing controllers
- Test full request/response cycle
- Use FactoryBot for test data creation
- Keep unit tests focused on single behaviors
- Test both happy and unhappy paths
- One expectation per unit test (multiple expectations OK for integration tests)
- Test edge cases and validations
- Use `let` for lazy-loading test data
- Organize with `describe` and `context` blocks

### CSS Architecture

- BEM methodology with `.component__element--modifier` pattern
- Foundation based on shadcn/ui aesthetic (without React)
- Propshaft for asset management
- Components organized in separate files (buttons, forms, tables, etc.)
- All styles must be explicitly imported in `application.css`
- Component prefix: `ap-` for all PromptEngine components
- Color variables defined in `foundation.css`
- Spacing system based on 4px units

## Dependencies

- **Rails**: 8.0.2+ (mountable engine)
- **Ruby**: 3.0+
- **ruby_llm**: For AI provider integration
- **bcrypt**: For encryption support
- **RSpec Rails**: Testing framework
- **FactoryBot**: Test data generation
- **VCR**: External API testing
- **Capybara**: System testing
- **SimpleCov**: Code coverage
- **Rubocop Rails Omakase**: Code style enforcement

## Key Implementation Details

### Version Control System

- Automatic versioning tracks changes to content, system_message, and model settings
- Version history preserved with change descriptions
- One-click restore to any previous version
- Counter cache for efficient version counting

### Variable System

- Variables use `{{variable_name}}` syntax
- Automatic parameter detection and synchronization
- Type inference based on naming conventions
- Support for complex types (arrays, JSON)

### Playground Feature

- Live testing with real AI providers
- Supports multiple models (GPT-4, Claude, etc.)
- Real-time execution with streaming responses
- Token counting and cost estimation
- PDF file support for document analysis and processing

### Engine Integration

The engine is designed to be mounted in Rails applications:

```ruby
# Host app's routes.rb
mount PromptEngine::Engine => "/prompt_engine"

# Usage in application
PromptEngine.render(:prompt_name, variables: { user_name: "John" })
```

## File Structure

```
app/
├── assets/stylesheets/prompt_engine/    # CSS files (BEM methodology)
├── controllers/prompt_engine/           # Engine controllers
├── models/prompt_engine/               # Models (Prompt, PromptVersion, Parameter)
├── services/prompt_engine/             # Service objects (VariableDetector, PlaygroundExecutor)
├── views/
│   ├── layouts/prompt_engine/          # Engine layouts
│   └── prompt_engine/                  # View templates
spec/
├── dummy/                              # Test Rails application
├── models/                             # Model specs
├── requests/                           # Request specs (controller testing)
├── services/                           # Service object specs
├── system/                             # System/feature specs
└── factories/                          # FactoryBot factories
```

## API Credentials Setup

PromptEngine requires API keys for AI providers. Configure in Rails credentials:

```bash
rails credentials:edit
```

Add:
```yaml
openai:
  api_key: sk-your-openai-api-key
anthropic:
  api_key: sk-ant-your-anthropic-api-key
```

## Host Application Integration

```ruby
# Gemfile
gem 'prompt_engine'

# config/routes.rb
mount PromptEngine::Engine => "/prompt_engine"

# In your application code
PromptEngine.render(:prompt_name, variables: { user_name: "John" })
```

## Current Status

**Implemented**: Core CRUD, version control, parameter management, playground, admin UI

**In Progress**: Analytics dashboard, evaluation suite, API endpoints

**Planned**: Multi-language support, A/B testing, prompt marketplace

See `docs/SPEC.md` for complete product vision and `docs/ARCHITECTURE.md` for detailed technical documentation.
