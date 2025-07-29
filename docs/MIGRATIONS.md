# PromptEngine Migration Guide

## Overview

PromptEngine handles migrations differently for development (dummy app) and production (host app) environments to avoid duplicate migration issues.

## Development Setup (Dummy App)

When developing the engine or running tests:

```bash
bundle exec rake setup
```

This command:
1. Clears existing migrations and databases
2. Installs engine migrations into the dummy app using `rails prompt_engine:install:migrations`
3. Creates and migrates both development and test databases

The engine's initializer **skips** appending migration paths for the dummy app to prevent duplicates.

## Production Setup (Host Application)

When installing PromptEngine in a Rails application:

### Option 1: Copy Migrations (Recommended)

```bash
bundle exec rails prompt_engine:install:migrations
bundle exec rails db:migrate
```

This copies migrations to your app with timestamps and `.prompt_engine.rb` suffix.

### Option 2: Runtime Loading

If you prefer not to copy migrations, the engine will automatically load them at runtime.
This happens through the engine's initializer for non-dummy applications.

## Troubleshooting Duplicate Migrations

If you encounter duplicate migration errors:

1. **Check for copied migrations**: Look in your app's `db/migrate` folder for `.prompt_engine.rb` files
2. **Remove duplicates**: If you have both copied migrations and runtime loading, remove the copied files
3. **Consistent approach**: Choose either copying OR runtime loading, not both

## Technical Details

The engine detects the dummy app environment and skips the migration path appending initializer to prevent Rails from seeing migrations twice. This is implemented in `lib/prompt_engine/engine.rb`:

```ruby
initializer :append_migrations do |app|
  unless app.root.to_s.match?(root.to_s) || app.root.to_s.include?('spec/dummy')
    # Only append migration paths for real host apps, not the dummy app
  end
end
```

This ensures clean migration handling in all environments.