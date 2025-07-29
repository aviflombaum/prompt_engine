# This migration comes from prompt_engine (originally 20250723161909)
class CreatePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_prompts do |t|
      t.string :name
      t.text :description
      t.text :content
      t.text :system_message
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.string :status
      t.json :metadata

      t.timestamps
    end
  end
end
