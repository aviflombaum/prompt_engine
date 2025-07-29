# This migration comes from prompt_engine (originally 20250724160623)
class CreatePromptEnginePlaygroundRunResults < ActiveRecord::Migration[7.0]
  def change
    create_table :prompt_engine_playground_run_results do |t|
      t.references :prompt_version, null: false, foreign_key: { to_table: :prompt_engine_prompt_versions }

      # API Provider and Model Info
      t.string :provider, null: false
      t.string :model, null: false

      # Prompt Details
      t.text :rendered_prompt, null: false
      t.text :system_message
      t.text :parameters

      # Response Details
      t.text :response, null: false
      t.float :execution_time, null: false
      t.integer :token_count

      # Settings Used
      t.float :temperature
      t.integer :max_tokens

      t.timestamps
    end

    add_index :prompt_engine_playground_run_results, :provider
    add_index :prompt_engine_playground_run_results, :created_at
  end
end
