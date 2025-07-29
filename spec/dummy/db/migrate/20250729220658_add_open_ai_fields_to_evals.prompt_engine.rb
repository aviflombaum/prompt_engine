# This migration comes from prompt_engine (originally 20250124000002)
class AddOpenAiFieldsToEvals < ActiveRecord::Migration[7.1]
  def change
    add_column :prompt_engine_eval_sets, :openai_eval_id, :string
    add_column :prompt_engine_eval_runs, :openai_run_id, :string
    add_column :prompt_engine_eval_runs, :openai_file_id, :string
    add_column :prompt_engine_eval_runs, :report_url, :string

    add_index :prompt_engine_eval_sets, :openai_eval_id
    add_index :prompt_engine_eval_runs, :openai_run_id
  end
end
