module PromptEngine
  class LlmExecution < ApplicationRecord
    self.table_name = "prompt_engine_llm_executions"
    
    belongs_to :usage
    has_one :prompt, through: :usage
    has_one :prompt_version, through: :usage
    
    validates :provider, :model, :status, presence: true
    validates :status, inclusion: { in: %w[pending success error timeout] }
    
    scope :successful, -> { where(status: "success") }
    scope :failed, -> { where(status: %w[error timeout]) }
    scope :by_provider, ->(provider) { where(provider: provider) }
    scope :by_model, ->(model) { where(model: model) }
    scope :recent, -> { order(created_at: :desc) }
    
    before_save :calculate_total_tokens
    after_update :calculate_cost_if_needed
    
    def successful?
      status == "success"
    end
    
    def failed?
      status.in?(%w[error timeout])
    end
    
    def pending?
      status == "pending"
    end
    
    def calculate_cost
      return 0 unless input_tokens.present? && output_tokens.present?
      
      cost_config = CostConfig.for_model(provider, model, created_at.to_date)
      return 0 unless cost_config
      
      input_cost = (input_tokens.to_f / 1000) * cost_config.input_token_cost
      output_cost = (output_tokens.to_f / 1000) * cost_config.output_token_cost
      (input_cost + output_cost).round(6)
    end
    
    def messages_count
      messages_sent.is_a?(Array) ? messages_sent.size : 0
    end
    
    private
    
    def calculate_total_tokens
      if input_tokens.present? && output_tokens.present?
        self.total_tokens = input_tokens + output_tokens
      end
    end
    
    def calculate_cost_if_needed
      if saved_change_to_input_tokens? || saved_change_to_output_tokens?
        update_column(:cost_usd, calculate_cost)
      end
    end
  end
end