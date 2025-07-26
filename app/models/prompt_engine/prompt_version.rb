module PromptEngine
  class PromptVersion < ApplicationRecord
    self.table_name = "prompt_engine_prompt_versions"

    belongs_to :prompt, class_name: "PromptEngine::Prompt", counter_cache: :versions_count
    has_many :playground_run_results, class_name: "PromptEngine::PlaygroundRunResult", dependent: :destroy
    has_many :eval_runs, class_name: "PromptEngine::EvalRun", dependent: :destroy
    has_many :usages, class_name: "PromptEngine::Usage", dependent: :destroy

    validates :version_number, presence: true,
              numericality: { greater_than: 0 },
              uniqueness: { scope: :prompt_id }
    validates :content, presence: true

    before_validation :set_version_number, on: :create
    validate :ensure_immutability, on: :update

    scope :latest, -> { order(version_number: :desc) }
    scope :chronological, -> { order(created_at: :asc) }

    def restore!
      # Update the prompt attributes
      prompt.update!(to_prompt_attributes)

      # Check if a version was created (attributes changed)
      latest_version = prompt.versions.first

      if latest_version.created_at > 1.second.ago
        # A new version was just created, update its description
        latest_version.update_column(:change_description, "Restored from version #{version_number}")
      else
        # No version was created (no changes), create one manually
        prompt.versions.create!(
          to_prompt_attributes.merge(
            change_description: "Restored from version #{version_number}"
          )
        )
      end
    end

    def to_prompt_attributes
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata
      }
    end

    private

    def set_version_number
      return if version_number.present?
      return unless prompt

      max_version = prompt.versions.maximum(:version_number) || 0
      self.version_number = max_version + 1
    end

    def ensure_immutability
      immutable_attributes = %w[content system_message model temperature max_tokens]
      changed_immutable = (changed & immutable_attributes)

      if changed_immutable.any?
        changed_immutable.each do |attr|
          errors.add(attr, "cannot be changed after creation")
        end
      end
    end
  end
end
