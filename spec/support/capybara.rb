require "capybara/cuprite"

# Register Cuprite driver
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [1200, 800],
    browser_options: {
      "no-sandbox": nil,
      "disable-dev-shm-usage": nil,
      "disable-gpu": nil
    },
    process_timeout: 30,
    timeout: 30,
    inspector: ENV["INSPECTOR"] == "true",
    headless: ENV["HEADLESS"] != "false"
  )
end

# Configure Capybara to use Cuprite for JS tests
Capybara.javascript_driver = :cuprite
Capybara.default_driver = :rack_test

# Set server to use in system tests
Capybara.server = :puma, { Silent: true }

# Configure for system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end

  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
  end
end