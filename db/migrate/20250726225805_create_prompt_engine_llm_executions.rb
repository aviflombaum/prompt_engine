class CreatePromptEngineLlmExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_llm_executions do |t|
      t.references :usage, null: false, foreign_key: { to_table: :prompt_engine_usages }
      t.string :provider
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.jsonb :messages_sent, default: []
      t.text :response_content
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :total_tokens
      t.decimal :execution_time_ms
      t.decimal :cost_usd, precision: 10, scale: 6
      t.string :status
      t.text :error_message
      t.jsonb :response_metadata, default: {}
      t.timestamps
    end

    add_index :prompt_engine_llm_executions, :provider
    add_index :prompt_engine_llm_executions, :model
    add_index :prompt_engine_llm_executions, :status
    add_index :prompt_engine_llm_executions, :created_at
  end
end