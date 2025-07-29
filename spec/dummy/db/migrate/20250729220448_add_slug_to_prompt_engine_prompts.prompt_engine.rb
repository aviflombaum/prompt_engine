# This migration comes from prompt_engine (originally 20250725201112)
class AddSlugToPromptEnginePrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompts, :slug, :string
    add_index :prompt_engine_prompts, :slug, unique: true
  end
end
