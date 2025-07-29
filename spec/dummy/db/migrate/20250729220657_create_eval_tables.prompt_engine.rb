# This migration comes from prompt_engine (originally 20250124000001)
class CreateEvalTables < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_engine_eval_sets do |t|
      t.string :name, null: false
      t.text :description
      t.references :prompt, null: false, foreign_key: { to_table: :prompt_engine_prompts }
      t.timestamps
    end

    create_table :prompt_engine_test_cases do |t|
      t.references :eval_set, null: false, foreign_key: { to_table: :prompt_engine_eval_sets }
      t.json :input_variables, null: false, default: {}
      t.text :expected_output, null: false
      t.text :description
      t.timestamps
    end

    create_table :prompt_engine_eval_runs do |t|
      t.references :eval_set, null: false, foreign_key: { to_table: :prompt_engine_eval_sets }
      t.references :prompt_version, null: false, foreign_key: { to_table: :prompt_engine_prompt_versions }
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_count, default: 0
      t.integer :passed_count, default: 0
      t.integer :failed_count, default: 0
      t.text :error_message
      t.timestamps
    end

    create_table :prompt_engine_eval_results do |t|
      t.references :eval_run, null: false, foreign_key: { to_table: :prompt_engine_eval_runs }
      t.references :test_case, null: false, foreign_key: { to_table: :prompt_engine_test_cases }
      t.text :actual_output
      t.boolean :passed, default: false
      t.integer :execution_time_ms
      t.text :error_message
      t.timestamps
    end

    add_index :prompt_engine_eval_sets, [ :prompt_id, :name ], unique: true
  end
end
