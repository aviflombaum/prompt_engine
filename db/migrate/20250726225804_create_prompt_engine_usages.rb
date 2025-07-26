class CreatePromptEngineUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_usages do |t|
      t.references :prompt, null: false, foreign_key: { to_table: :prompt_engine_prompts }
      t.references :prompt_version, null: false, foreign_key: { to_table: :prompt_engine_prompt_versions }
      t.string :environment
      t.string :session_id
      t.string :user_identifier
      t.jsonb :parameters_used, default: {}
      t.text :rendered_content
      t.text :rendered_system_message
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :prompt_engine_usages, :environment
    add_index :prompt_engine_usages, :session_id
    add_index :prompt_engine_usages, :created_at
  end
end