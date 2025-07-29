# This migration comes from prompt_engine (originally 20250723203838)
class CreatePromptEngineParameters < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_parameters do |t|
      t.references :prompt, null: false, foreign_key: { to_table: :prompt_engine_prompts }
      t.string :name, null: false
      t.text :description
      t.string :parameter_type, null: false, default: 'string'
      t.boolean :required, null: false, default: true
      t.string :default_value
      t.json :validation_rules
      t.string :example_value
      t.integer :position

      t.timestamps
    end

    add_index :prompt_engine_parameters, [ :prompt_id, :name ], unique: true
    add_index :prompt_engine_parameters, :position
  end
end
