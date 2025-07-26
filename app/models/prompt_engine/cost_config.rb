module PromptEngine
  class CostConfig < ApplicationRecord
    self.table_name = "prompt_engine_cost_configs"
    
    validates :provider, :model, :input_token_cost, :output_token_cost, presence: true
    validates :provider, inclusion: { in: %w[openai anthropic] }
    validates :input_token_cost, :output_token_cost, 
              numericality: { greater_than_or_equal_to: 0 }
    validates :effective_from, presence: true
    
    validate :effective_dates_valid
    
    scope :active, ->(date = Date.current) {
      where("effective_from <= ?", date)
        .where("effective_until IS NULL OR effective_until >= ?", date)
    }
    scope :by_provider, ->(provider) { where(provider: provider) }
    
    def self.for_model(provider, model, date = Date.current)
      where(provider: provider, model: model)
        .active(date)
        .order(effective_from: :desc)
        .first
    end
    
    def self.seed_default_costs
      transaction do
        # OpenAI Models
        create_or_update_cost("openai", "gpt-4o", 0.00500, 0.01500, Date.new(2024, 1, 1))
        create_or_update_cost("openai", "gpt-4o-mini", 0.00015, 0.00060, Date.new(2024, 1, 1))
        create_or_update_cost("openai", "gpt-4-turbo", 0.01000, 0.03000, Date.new(2024, 1, 1))
        create_or_update_cost("openai", "gpt-3.5-turbo", 0.00050, 0.00150, Date.new(2024, 1, 1))
        
        # Anthropic Models
        create_or_update_cost("anthropic", "claude-3-5-sonnet-20241022", 0.00300, 0.01500, Date.new(2024, 1, 1))
        create_or_update_cost("anthropic", "claude-3-opus-20240229", 0.01500, 0.07500, Date.new(2024, 1, 1))
        create_or_update_cost("anthropic", "claude-3-haiku-20240307", 0.00025, 0.00125, Date.new(2024, 1, 1))
      end
    end
    
    def active?(date = Date.current)
      date >= effective_from && (effective_until.nil? || date <= effective_until)
    end
    
    def cost_per_1k_tokens
      {
        input: input_token_cost,
        output: output_token_cost,
        average: (input_token_cost + output_token_cost) / 2
      }
    end
    
    private
    
    def self.create_or_update_cost(provider, model, input_cost, output_cost, effective_from)
      cost_config = find_or_initialize_by(
        provider: provider,
        model: model,
        effective_from: effective_from
      )
      
      cost_config.update!(
        input_token_cost: input_cost,
        output_token_cost: output_cost
      )
    end
    
    def effective_dates_valid
      if effective_until.present? && effective_from.present? && effective_until < effective_from
        errors.add(:effective_until, "must be after effective_from")
      end
    end
  end
end