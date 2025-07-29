# desc "Explaining what the task does"
# task :prompt_engine do
#   # Task goes here
# end

namespace :prompt_engine do
  desc "Setup dummy app for development and testing"
  task setup: :environment do
    puts "Setting up PromptEngine dummy app..."

    dummy_root = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_root) do
      # Remove existing migrations and schema
      FileUtils.rm_rf(Dir.glob("db/migrate/*"))
      FileUtils.rm_f("db/schema.rb")
      FileUtils.rm_f("db/development.sqlite3")
      FileUtils.rm_f("db/test.sqlite3")

      # Install engine migrations
      system("bundle exec rails prompt_engine:install:migrations")

      # Create and migrate databases
      system("bundle exec rails db:create")
      system("bundle exec rails db:migrate")
      system("RAILS_ENV=test bundle exec rails db:create")
      system("RAILS_ENV=test bundle exec rails db:migrate")

      puts "✅ PromptEngine dummy app setup complete!"
    end
  end
end
