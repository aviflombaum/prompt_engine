class CreatePromptEngineCostConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_cost_configs do |t|
      t.string :provider, null: false
      t.string :model, null: false
      t.decimal :input_token_cost, precision: 10, scale: 8
      t.decimal :output_token_cost, precision: 10, scale: 8
      t.date :effective_from
      t.date :effective_until
      t.timestamps
    end

    add_index :prompt_engine_cost_configs, [:provider, :model, :effective_from], name: "index_cost_configs_on_provider_model_date"
  end
end