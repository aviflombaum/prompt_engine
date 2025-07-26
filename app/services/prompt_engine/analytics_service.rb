module PromptEngine
  class AnalyticsService
    class << self
      def usage_stats(prompt: nil, date_range: nil)
        scope = Usage.all
        scope = scope.where(prompt: prompt) if prompt
        scope = scope.where(created_at: date_range) if date_range
        
        executions_scope = scope.joins(:llm_execution)
        
        {
          total_uses: scope.count,
          total_executions: executions_scope.count,
          success_rate: calculate_success_rate(executions_scope),
          total_cost: executions_scope.sum("prompt_engine_llm_executions.cost_usd"),
          average_tokens: executions_scope.average("prompt_engine_llm_executions.total_tokens")&.to_i,
          average_latency_ms: executions_scope.average("prompt_engine_llm_executions.execution_time_ms")&.round(1),
          by_environment: scope.group(:environment).count,
          by_model: executions_scope.group("prompt_engine_llm_executions.model").count
        }
      end
      
      def prompt_performance(prompt, date_range: 30.days.ago..Time.current)
        executions = prompt.usages
          .joins(:llm_execution)
          .where(created_at: date_range)
          .includes(:llm_execution)
        
        {
          total_executions: executions.count,
          average_latency_ms: executions.average("prompt_engine_llm_executions.execution_time_ms")&.round(1),
          error_rate: calculate_error_rate(executions),
          success_rate: calculate_success_rate(executions),
          cost_by_day: cost_by_day(executions, date_range),
          usage_by_version: usage_by_version(prompt, date_range),
          model_distribution: model_distribution(executions),
          token_usage: token_usage_stats(executions)
        }
      end
      
      def cost_breakdown(date_range: 7.days.ago..Time.current, group_by: :prompt)
        executions = LlmExecution.joins(:usage).where(prompt_engine_usages: { created_at: date_range })
        
        case group_by
        when :prompt
          executions
            .joins(usage: :prompt)
            .group("prompt_engine_prompts.name")
            .sum(:cost_usd)
            .transform_values { |v| v.round(2) }
        when :model
          executions
            .group(:model)
            .sum(:cost_usd)
            .transform_values { |v| v.round(2) }
        when :provider
          executions
            .group(:provider)
            .sum(:cost_usd)
            .transform_values { |v| v.round(2) }
        when :day
          group_by_day(executions, "prompt_engine_llm_executions.created_at")
            .sum(:cost_usd)
            .transform_values { |v| v.round(2) }
        else
          { total: executions.sum(:cost_usd).round(2) }
        end
      end
      
      def error_analysis(date_range: 24.hours.ago..Time.current)
        failed_executions = LlmExecution
          .failed
          .joins(:usage)
          .where(prompt_engine_usages: { created_at: date_range })
          .includes(usage: :prompt)
        
        errors_by_type = failed_executions.group(:error_message).count
        errors_by_prompt = failed_executions
          .group("prompt_engine_prompts.name")
          .joins(usage: :prompt)
          .count
        
        {
          total_errors: failed_executions.count,
          errors_by_type: categorize_errors(errors_by_type),
          errors_by_prompt: errors_by_prompt,
          recent_errors: failed_executions.recent.limit(10).map do |execution|
            {
              prompt: execution.prompt.name,
              error: execution.error_message,
              model: execution.model,
              timestamp: execution.created_at
            }
          end
        }
      end
      
      def top_prompts(date_range: 7.days.ago..Time.current, limit: 10)
        Usage
          .where(created_at: date_range)
          .joins(:prompt)
          .group("prompt_engine_prompts.id", "prompt_engine_prompts.name")
          .order("count_all DESC")
          .limit(limit)
          .count
          .map do |(prompt_id, prompt_name), count|
            prompt = Prompt.find(prompt_id)
            stats = usage_stats(prompt: prompt, date_range: date_range)
            {
              name: prompt_name,
              usage_count: count,
              execution_count: stats[:total_executions],
              total_cost: stats[:total_cost]&.round(2),
              success_rate: stats[:success_rate]
            }
          end
      end
      
      private
      
      def calculate_success_rate(executions_scope)
        total = executions_scope.count
        return 0 if total == 0
        
        successful = executions_scope.where("prompt_engine_llm_executions.status = ?", "success").count
        ((successful.to_f / total) * 100).round(1)
      end
      
      def calculate_error_rate(executions_scope)
        total = executions_scope.count
        return 0 if total == 0
        
        failed = executions_scope.where("prompt_engine_llm_executions.status IN (?)", ["error", "timeout"]).count
        ((failed.to_f / total) * 100).round(1)
      end
      
      def cost_by_day(executions, date_range)
        start_date = date_range.begin.to_date
        end_date = date_range.end.to_date
        
        daily_costs = group_by_day(executions, "prompt_engine_llm_executions.created_at")
          .sum("prompt_engine_llm_executions.cost_usd")
        
        # Fill in missing days with 0
        (start_date..end_date).map do |date|
          [date.to_s, (daily_costs[date.to_s] || 0).round(2)]
        end.to_h
      end
      
      def usage_by_version(prompt, date_range)
        prompt.usages
          .where(created_at: date_range)
          .joins(:prompt_version)
          .group("prompt_engine_prompt_versions.version_number")
          .count
      end
      
      def model_distribution(executions)
        executions
          .group("prompt_engine_llm_executions.model")
          .count
      end
      
      def token_usage_stats(executions)
        {
          total_input_tokens: executions.sum("prompt_engine_llm_executions.input_tokens"),
          total_output_tokens: executions.sum("prompt_engine_llm_executions.output_tokens"),
          average_input_tokens: executions.average("prompt_engine_llm_executions.input_tokens")&.to_i,
          average_output_tokens: executions.average("prompt_engine_llm_executions.output_tokens")&.to_i
        }
      end
      
      def categorize_errors(errors_by_message)
        categories = {
          rate_limit: 0,
          authentication: 0,
          network: 0,
          timeout: 0,
          invalid_request: 0,
          other: 0
        }
        
        errors_by_message.each do |message, count|
          case message.to_s.downcase
          when /rate limit/
            categories[:rate_limit] += count
          when /unauthorized|invalid.*key|authentication/
            categories[:authentication] += count
          when /network|connection/
            categories[:network] += count
          when /timeout/
            categories[:timeout] += count
          when /invalid.*request|bad request/
            categories[:invalid_request] += count
          else
            categories[:other] += count
          end
        end
        
        categories
      end
      
      # Simple group_by_day implementation without external dependencies
      def group_by_day(scope, column)
        # Use DATE() function to group by date (works in PostgreSQL, MySQL, SQLite)
        scope.group("DATE(#{column})")
      end
    end
  end
end