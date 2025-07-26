module PromptEngine
  class Usage < ApplicationRecord
    self.table_name = "prompt_engine_usages"
    
    belongs_to :prompt
    belongs_to :prompt_version
    has_one :llm_execution, dependent: :destroy
    
    validates :rendered_content, presence: true
    
    scope :by_environment, ->(env) { where(environment: env) }
    scope :recent, -> { order(created_at: :desc) }
    scope :with_execution, -> { joins(:llm_execution) }
    scope :by_prompt, ->(prompt) { where(prompt: prompt) }
    scope :by_session, ->(session_id) { where(session_id: session_id) }
    scope :by_user, ->(user_identifier) { where(user_identifier: user_identifier) }
    
    def executed?
      llm_execution.present?
    end
    
    def successful?
      llm_execution&.successful?
    end
    
    def failed?
      llm_execution&.failed?
    end
    
    def cost
      llm_execution&.cost_usd || 0
    end
    
    def execution_time
      llm_execution&.execution_time_ms
    end
    
    def total_tokens
      llm_execution&.total_tokens || 0
    end
    
    def response_content
      llm_execution&.response_content
    end
  end
end