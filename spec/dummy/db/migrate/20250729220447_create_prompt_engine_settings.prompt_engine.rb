# This migration comes from prompt_engine (originally 20250724165118)
class CreatePromptEngineSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :prompt_engine_settings do |t|
      # Encrypted API keys
      t.text :openai_api_key
      t.text :anthropic_api_key

      # Other settings can be added here in the future
      t.json :preferences, default: {}

      t.timestamps
    end
  end
end
