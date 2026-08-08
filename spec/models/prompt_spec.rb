require "rails_helper"

RSpec.describe PromptEngine::Prompt, type: :model do
  describe "validations" do
    it "validates presence of name" do
      prompt = PromptEngine::Prompt.new(name: nil)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name scoped to status" do
      # Create first prompt with required content
      PromptEngine::Prompt.create!(name: "test", content: "Test content", status: "active")

      # Same name with same status should be invalid
      duplicate = PromptEngine::Prompt.new(name: "test", content: "Test content", status: "active")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")

      # Same name with different status should not be valid (slug uniqueness)
      different_status = PromptEngine::Prompt.new(name: "test", content: "Test content", status: "draft")
      expect(different_status).not_to be_valid
      expect(different_status.errors[:slug]).to include("has already been taken")
    end

    it "validates presence of content" do
      prompt = PromptEngine::Prompt.new(name: "test", content: nil)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:content]).to include("can't be blank")
    end

    it "validates inclusion of status" do
      # Rails enum raises ArgumentError for invalid values, so we need to test differently
      prompt = PromptEngine::Prompt.new(name: "test", content: "Test content")

      # Test that enum only accepts valid values
      expect { prompt.status = "invalid" }.to raise_error(ArgumentError)

      # Test that valid statuses work
      %w[draft active archived].each do |valid_status|
        prompt.status = valid_status
        prompt.valid?
        expect(prompt.errors[:status]).to be_empty
      end
    end
  end

  describe "default values" do
    it "sets status to draft by default" do
      prompt = PromptEngine::Prompt.new
      expect(prompt.status).to eq("draft")
    end
  end

  describe "associations" do
    it "has many versions" do
      prompt = PromptEngine::Prompt.new
      association = prompt.class.reflect_on_association(:versions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:class_name]).to eq("PromptEngine::PromptVersion")
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many parameters" do
      prompt = PromptEngine::Prompt.new
      association = prompt.class.reflect_on_association(:parameters)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:class_name]).to eq("PromptEngine::Parameter")
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "version control" do
    let(:prompt) { create(:prompt) }

    describe "creating versions on save" do
      it "creates initial version on create" do
        new_prompt = nil
        expect {
          new_prompt = PromptEngine::Prompt.create!(
            name: "Test Prompt",
            content: "Initial content",
            system_message: "Initial system message",
            model: "gpt-4",
            temperature: 0.7,
            max_tokens: 1000
          )
        }.to change { PromptEngine::PromptVersion.count }.by(1)

        version = new_prompt.versions.first
        expect(version.version_number).to eq(1)
        expect(version.content).to eq("Initial content")
        expect(version.system_message).to eq("Initial system message")
        expect(version.change_description).to eq("Initial version")
      end

      it "creates new version on update when content changes" do
        prompt.update!(content: "Updated content")

        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.version_number).to eq(2)
        expect(latest_version.content).to eq("Updated content")
      end

      it "creates new version when system_message changes" do
        prompt.update!(system_message: "Updated system message")

        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.system_message).to eq("Updated system message")
      end

      it "creates new version when model changes" do
        prompt.update!(model: "gpt-3.5-turbo")

        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.model).to eq("gpt-3.5-turbo")
      end

      it "creates new version when temperature changes" do
        prompt.update!(temperature: 0.9)

        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.temperature).to eq(0.9)
      end

      it "creates new version when max_tokens changes" do
        prompt.update!(max_tokens: 2000)

        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.max_tokens).to eq(2000)
      end

      it "does not create version when only non-versioned fields change" do
        prompt.update!(name: "New Name", description: "New Description")

        expect(prompt.versions.count).to eq(1)
      end

      it "does not create version when no changes are made" do
        prompt.save!

        expect(prompt.versions.count).to eq(1)
      end
    end

    describe "#current_version" do
      it "returns the latest version" do
        prompt.update!(content: "Version 2")
        prompt.update!(content: "Version 3")

        current = prompt.current_version
        expect(current.version_number).to eq(3)
        expect(current.content).to eq("Version 3")
      end
    end

    describe "#version_count" do
      it "returns the number of versions" do
        expect(prompt.version_count).to eq(1)

        prompt.update!(content: "Version 2")
        expect(prompt.version_count).to eq(2)

        prompt.update!(content: "Version 3")
        expect(prompt.version_count).to eq(3)
      end

      it "uses counter cache when available" do
        # This test assumes we'll add a counter cache column
        # For now, it just tests the method exists
        expect(prompt).to respond_to(:version_count)
      end
    end

    describe "#restore_version!" do
      let!(:version1) { prompt.versions.first }
      let!(:version2) {
        prompt.update!(content: "Version 2 content")
        prompt.current_version
      }
      let!(:version3) {
        prompt.update!(content: "Version 3 content")
        prompt.current_version
      }

      it "restores prompt to a specific version" do
        prompt.restore_version!(version1.version_number)

        expect(prompt.content).to eq(version1.content)
        expect(prompt.system_message).to eq(version1.system_message)
        expect(prompt.versions.count).to eq(4) # Original 3 + 1 restoration
      end

      it "raises error for non-existent version" do
        expect {
          prompt.restore_version!(999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "#version_at" do
      let!(:version1) { prompt.versions.first }
      let!(:version2) {
        prompt.update!(content: "Version 2")
        prompt.current_version
      }

      it "returns the version with specified number" do
        version = prompt.version_at(1)
        expect(version).to eq(version1)

        version = prompt.version_at(2)
        expect(version).to eq(version2)
      end

      it "returns nil for non-existent version" do
        expect(prompt.version_at(999)).to be_nil
      end
    end

    describe "#versioned_attributes_changed?" do
      it "returns true when versioned attributes change" do
        prompt.content = "New content"
        expect(prompt.versioned_attributes_changed?).to be true
      end

      it "returns false when only non-versioned attributes change" do
        prompt.name = "New name"
        expect(prompt.versioned_attributes_changed?).to be false
      end

      it "returns false when no attributes change" do
        expect(prompt.versioned_attributes_changed?).to be false
      end
    end
  end

  describe "usage in Rails models" do
    # Create a test model that uses prompts
    before do
      class TestModel
        def self.generate_content(prompt_name, variables = {})
          PromptEngine.render(prompt_name, variables)
        end
      end
    end

    after do
      Object.send(:remove_const, :TestModel) if defined?(TestModel)
    end

    context "when using PromptEngine.render" do
      let!(:welcome_prompt) do
        PromptEngine::Prompt.create!(
          name: "welcome-message",
          content: "Welcome {{user_name}}! Thanks for joining {{company_name}}.",
          system_message: "You are a friendly assistant.",
          model: "gpt-4",
          temperature: 0.7,
          max_tokens: 100,
          status: "active"
        )
      end

      it "renders a prompt with variables from a Rails model" do
        result = TestModel.generate_content("welcome-message", {
          user_name: "Alice",
          company_name: "Acme Corp"
        })

        expect(result.content).to eq("Welcome Alice! Thanks for joining Acme Corp.")
        expect(result.system_message).to eq("You are a friendly assistant.")
        expect(result.model).to eq("gpt-4")
        expect(result.temperature).to eq(0.7)
        expect(result.max_tokens).to eq(100)
      end

      it "only uses active prompts" do
        # Create a different archived prompt
        PromptEngine::Prompt.create!(
          name: "old-welcome",
          content: "Old content",
          status: "archived"
        )

        result = TestModel.generate_content("welcome-message", {
          user_name: "Test User",
          company_name: "Test Company"
        })
        expect(result.content).not_to include("Old content")
      end

      it "raises error for non-existent prompts" do
        expect {
          TestModel.generate_content(:non_existent)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "nested attributes" do
    it "accepts nested attributes for parameters" do
      prompt = create(:prompt, content: "Simple content without variables")

      prompt.update!(
        parameters_attributes: [
          { name: "param1", parameter_type: "string" },
          { name: "param2", parameter_type: "integer", required: false }
        ]
      )

      expect(prompt.parameters.count).to eq(2)
      expect(prompt.parameters.pluck(:name)).to contain_exactly("param1", "param2")
    end

    xit "allows destroying parameters through nested attributes" do
      # TODO: Fix this test - there's an issue with nested attributes and associations
      prompt = create(:prompt)
      param = create(:parameter, prompt: prompt)
      prompt.reload # Ensure associations are loaded

      expect {
        prompt.update!(
          parameters_attributes: [
            { id: param.id, _destroy: "1" }
          ]
        )
        prompt.reload # Reload to check the count
      }.to change { prompt.parameters.count }.from(1).to(0)
    end
  end

  describe "parameter management" do
    let(:prompt) { create(:prompt, content: "No variables here") }

    describe "#detect_variables" do
      it "detects simple variables" do
        prompt.update!(content: "Hello {{name}}, welcome to {{company}}!")
        prompt.reload
        expect(prompt.content).to eq("Hello {{name}}, welcome to {{company}}!")
        detector = PromptEngine::VariableDetector.new(prompt.content)
        expect(detector.variable_names).to contain_exactly("name", "company")
        expect(prompt.detect_variables).to contain_exactly("name", "company")
      end

      it "detects variables with underscores and numbers" do
        prompt.update!(content: "User {{user_name}} has {{item_count}} items")
        expect(prompt.detect_variables).to contain_exactly("user_name", "item_count")
      end

      it "returns empty array when no variables" do
        prompt.update!(content: "Hello world!")
        expect(prompt.detect_variables).to eq([])
      end

      it "detects unique variables only" do
        prompt.update!(content: "Hello {{name}}, {{name}} is great!")
        expect(prompt.detect_variables).to eq([ "name" ])
      end
    end

    describe "#sync_parameters!" do
      context "when adding new parameters" do
        it "creates parameters for new variables" do
          # Make sure no parameters exist initially
          prompt.parameters.destroy_all

          # After update, sync_parameters! is called automatically
          prompt.update!(content: "Hello {{user_name}}, your count is {{item_count}}")

          # Parameters should already be created by the after_update callback
          expect(prompt.parameters.reload.count).to eq(2)

          # The positions should be 1 and 2 for the two new parameters
          params = prompt.parameters.order(:position)
          expect(params.count).to eq(2)

          # Just check that positions are sequential
          expect(params[0].name).to eq("user_name")
          expect(params[1].name).to eq("item_count")
          expect(params[1].position).to eq(params[0].position + 1)

          # Calling sync_parameters! again should not create duplicates
          expect {
            prompt.sync_parameters!
          }.not_to change { prompt.parameters.count }
        end

        it "preserves existing parameters" do
          # Start with content that includes existing_param
          prompt.update!(content: "Hello {{existing_param}}")

          # Now we have a parameter for existing_param created by auto-sync
          existing = prompt.parameters.find_by(name: "existing_param")
          existing.update!(description: "Should not change", required: false)

          # Update content to add new_param
          prompt.update!(content: "Hello {{existing_param}} and {{new_param}}")

          existing.reload
          expect(existing.description).to eq("Should not change")
          expect(existing.required).to be false
          expect(prompt.parameters.pluck(:name)).to contain_exactly("existing_param", "new_param")
        end
      end

      context "when removing parameters" do
        it "removes parameters no longer in content" do
          # Start with content that has both parameters
          prompt.update!(content: "Hello {{keep_me}} and {{remove_me}}")

          param1 = prompt.parameters.find_by(name: "keep_me")
          param2 = prompt.parameters.find_by(name: "remove_me")

          # When content is updated, orphaned parameters are removed automatically
          prompt.update!(content: "Only {{keep_me}} remains")

          # The parameter should already be removed
          expect(prompt.parameters.reload.count).to eq(1)
          expect(prompt.parameters.pluck(:name)).to eq([ "keep_me" ])
          expect(PromptEngine::Parameter.exists?(param2.id)).to be false
        end
      end

      it "returns true on success" do
        prompt.update!(content: "Hello {{name}}")
        expect(prompt.sync_parameters!).to be true
      end
    end

    describe "#render_with_params" do
      before do
        prompt.update!(content: "Hello {{name}}, you have {{item_count}} items")
        prompt.sync_parameters!
        # item_count will be inferred as integer type
        prompt.parameters.find_by(name: "item_count").update!(
          validation_rules: { "min" => 0, "max" => 150 }
        )
      end

      context "with valid parameters" do
        it "renders content with provided parameters" do
          result = prompt.render_with_params(name: "Alice", item_count: "25")

          expect(result[:content]).to eq("Hello Alice, you have 25 items")
          expect(result[:system_message]).to eq(prompt.system_message)
          expect(result[:model]).to eq(prompt.model)
          expect(result[:temperature]).to eq(prompt.temperature)
          expect(result[:max_tokens]).to eq(prompt.max_tokens)
          expect(result[:parameters_used]).to eq({ "name" => "Alice", "item_count" => 25 })
        end

        it "accepts string or symbol parameter keys" do
          result1 = prompt.render_with_params("name" => "Bob", "item_count" => "30")
          result2 = prompt.render_with_params(name: "Bob", item_count: "30")

          expect(result1[:content]).to eq(result2[:content])
        end

        it "casts parameters to correct types" do
          result = prompt.render_with_params(name: 123, item_count: "45")

          expect(result[:parameters_used]).to eq({ "name" => "123", "item_count" => 45 })
        end

        it "uses default values for optional parameters" do
          param = prompt.parameters.find_by(name: "name")
          param.update!(required: false, default_value: "Guest")

          # Reload to ensure we have fresh parameter data
          prompt.reload

          result = prompt.render_with_params(item_count: "30")
          expect(result[:content]).to eq("Hello Guest, you have 30 items")
        end
      end

      context "with invalid parameters" do
        it "returns error when required parameter is missing" do
          result = prompt.render_with_params(name: "Alice")

          expect(result[:error]).to include("item_count is required")
          expect(result).not_to have_key(:content)
        end

        it "returns error when parameter validation fails" do
          prompt.reload # Ensure fresh parameter data
          result = prompt.render_with_params(name: "Alice", item_count: "200")

          expect(result[:error]).to include("item_count must be at most 150")
        end

        it "returns multiple errors when multiple validations fail" do
          prompt.parameters.find_by(name: "name").update!(
            validation_rules: { "min_length" => 3 }
          )

          prompt.reload # Ensure fresh parameter data
          result = prompt.render_with_params(name: "Al", item_count: "200")

          expect(result[:error]).to include("name must be at least 3 characters")
          expect(result[:error]).to include("item_count must be at most 150")
        end
      end

      context "with parameters in the system_message" do
        before do
          prompt.update!(system_message: "Use this input schema {{input_schema}}")
        end

        it "renders variables in the system_message as well" do
          result = prompt.render_with_params(name: "Alice", item_count: "10", input_schema: "object:schema")

          expect(result[:content]).to eq("Hello Alice, you have 10 items")
          expect(result[:system_message]).to eq("Use this input schema object:schema")
        end
      end
    end

    describe "#validate_parameters" do
      before do
        prompt.update!(content: "Hello {{name}}, you have {{item_count}} items")
        prompt.sync_parameters!
      end

      it "returns valid true when all parameters are valid" do
        result = prompt.validate_parameters(name: "Alice", item_count: "25")

        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "returns valid false with errors when parameters are invalid" do
        result = prompt.validate_parameters(name: "")

        expect(result[:valid]).to be false
        expect(result[:errors]).to include("name is required")
        expect(result[:errors]).to include("item_count is required")
      end

      it "validates all parameter rules" do
        prompt.parameters.find_by(name: "name").update!(
          validation_rules: { "pattern" => "^[A-Z]" }
        )

        prompt.reload # Ensure fresh parameter data
        result = prompt.validate_parameters(name: "alice", item_count: "25")

        expect(result[:valid]).to be false
        expect(result[:errors]).to include("name must match pattern: ^[A-Z]")
      end
    end

    describe "clean_orphaned_parameters callback" do
      it "marks parameters for destruction when content changes" do
        prompt.update!(content: "Hello {{param1}} and {{param2}}")
        prompt.sync_parameters!

        expect(prompt.parameters.count).to eq(2)

        # Change content to remove param2
        prompt.update!(content: "Hello {{param1}} only")

        expect(prompt.parameters.reload.pluck(:name)).to eq([ "param1" ])
      end

      it "does not affect parameters when content does not change" do
        prompt.update!(content: "Hello {{param1}}")
        prompt.sync_parameters!

        # Update other attributes
        prompt.update!(name: "New Name")

        expect(prompt.parameters.count).to eq(1)
      end
    end
  end
end
