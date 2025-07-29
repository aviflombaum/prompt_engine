# This migration comes from prompt_engine (originally 20250125000001)
class AddGraderFieldsToEvalSets < ActiveRecord::Migration[7.1]
  def change
    add_column :prompt_engine_eval_sets, :grader_type, :string, default: 'exact_match', null: false
    add_column :prompt_engine_eval_sets, :grader_config, :json, default: {}

    add_index :prompt_engine_eval_sets, :grader_type
  end
end
