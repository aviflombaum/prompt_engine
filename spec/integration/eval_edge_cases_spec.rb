require 'rails_helper'

RSpec.describe "Evaluation Edge Cases", type: :integration do
  let(:prompt) { create(:prompt) }
  let(:prompt_version) { create(:prompt_version, prompt: prompt) }

  describe "Invalid grader configurations" do
    context "regex grader with invalid pattern" do
      it "validates regex pattern on save" do
        eval_set = build(:eval_set,
          prompt: prompt,
          grader_type: 'regex',
          grader_config: { 'pattern' => '[invalid(' }
        )

        expect(eval_set).not_to be_valid
        expect(eval_set.errors[:grader_config]).to include(/invalid regex pattern/)
      end

      it "handles empty regex pattern" do
        eval_set = build(:eval_set,
          prompt: prompt,
          grader_type: 'regex',
          grader_config: { 'pattern' => '' }
        )

        expect(eval_set).not_to be_valid
        expect(eval_set.errors[:grader_config]).to include("regex pattern is required")
      end
    end

    context "json_schema grader with invalid schema" do
      it "validates JSON schema structure" do
        eval_set = build(:eval_set,
          prompt: prompt,
          grader_type: 'json_schema',
          grader_config: { 'schema' => 'not a hash' }
        )

        expect(eval_set).not_to be_valid
      end

      it "requires type field in schema" do
        eval_set = build(:eval_set,
          prompt: prompt,
          grader_type: 'json_schema',
          grader_config: {
            'schema' => {
              'properties' => { 'name' => { 'type' => 'string' } }
            }
          }
        )

        expect(eval_set).not_to be_valid
        expect(eval_set.errors[:grader_config]).to include("JSON schema must include a 'type' field")
      end
    end

    context "grader type changes after test cases exist" do
      let(:eval_set) do
        create(:eval_set,
          prompt: prompt,
          grader_type: 'exact_match'
        )
      end

      let!(:test_cases) do
        3.times.map do
          create(:test_case,
            eval_set: eval_set,
            expected_output: "Simple text output"
          )
        end
      end

      it "allows changing to contains grader" do
        eval_set.grader_type = 'contains'
        expect(eval_set).to be_valid
        expect(eval_set.save).to be true
      end

      it "validates when changing to regex grader" do
        eval_set.grader_type = 'regex'
        eval_set.grader_config = { 'pattern' => '^Simple.*output$' }
        expect(eval_set).to be_valid
      end

      it "prevents invalid regex patterns even with existing test cases" do
        eval_set.grader_type = 'regex'
        eval_set.grader_config = { 'pattern' => '[invalid' }
        expect(eval_set).not_to be_valid
      end
    end
  end

  describe "Empty eval sets" do
    let(:empty_eval_set) { create(:eval_set, prompt: prompt) }

    it "cannot run evaluation without test cases" do
      expect(empty_eval_set.ready_to_run?).to be false
    end

    it "shows appropriate message when trying to run" do
      # Set up API key
      PromptEngine::Setting.instance.update!(openai_api_key: 'sk-test-key-123')

      eval_run = empty_eval_set.eval_runs.create!(
        prompt_version: prompt_version
      )

      runner = PromptEngine::EvaluationRunner.new(eval_run)

      # Mock the client
      mock_client = instance_double(PromptEngine::OpenAiEvalsClient)
      allow(PromptEngine::OpenAiEvalsClient).to receive(:new).and_return(mock_client)

      # Mock create_eval to succeed (since it's called first)
      allow(mock_client).to receive(:create_eval).and_return({ 'id' => 'test-eval-123' })
      
      # Mock upload_file to simulate uploading empty file - this should fail or return an error
      allow(mock_client).to receive(:upload_file).and_raise(
        PromptEngine::OpenAiEvalsClient::APIError, "File contains no data"
      )

      # Should fail when trying to upload empty test data
      expect { runner.execute }.to raise_error(PromptEngine::OpenAiEvalsClient::APIError, "File contains no data")

      # The status should be failed with the error message
      eval_run.reload
      expect(eval_run.status).to eq("failed")
      expect(eval_run.error_message).to eq("File contains no data")
    end

    it "allows adding test cases after creation" do
      expect(empty_eval_set.test_cases.count).to eq(0)

      test_case = create(:test_case, eval_set: empty_eval_set)

      expect(empty_eval_set.reload.test_cases.count).to eq(1)
      expect(empty_eval_set.ready_to_run?).to be true
    end
  end

  describe "Failed evaluations" do
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let!(:test_cases) { create_list(:test_case, 3, eval_set: eval_set) }

    context "API failures" do
      let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version) }
      let(:runner) { PromptEngine::EvaluationRunner.new(eval_run) }

      before do
        mock_client = instance_double(PromptEngine::OpenAiEvalsClient)
        allow(PromptEngine::OpenAiEvalsClient).to receive(:new).and_return(mock_client)
        @mock_client = mock_client
      end

      it "handles file upload failures" do
        # Mock create_eval to succeed (called in ensure_openai_eval_exists)
        allow(@mock_client).to receive(:create_eval).and_return({ 'eval_id' => 'test-eval-123' })

        # Mock upload_file to fail
        allow(@mock_client).to receive(:upload_file).and_raise(
          PromptEngine::OpenAiEvalsClient::APIError, "File upload failed"
        )

        expect { runner.execute }.to raise_error(PromptEngine::OpenAiEvalsClient::APIError)

        eval_run.reload
        expect(eval_run.status).to eq("failed")
        expect(eval_run.error_message).to eq("File upload failed")
      end

      it "handles eval creation failures" do
        allow(@mock_client).to receive(:create_eval).and_raise(
          PromptEngine::OpenAiEvalsClient::APIError, "Invalid eval configuration"
        )

        expect { runner.execute }.to raise_error(PromptEngine::OpenAiEvalsClient::APIError)

        eval_run.reload
        expect(eval_run.status).to eq("failed")
        expect(eval_run.error_message).to eq("Invalid eval configuration")
      end

      it "handles run creation failures" do
        allow(@mock_client).to receive(:create_eval).and_return({ "id" => "eval_123" })
        allow(@mock_client).to receive(:upload_file).and_return({ "id" => "file_123" })
        allow(@mock_client).to receive(:create_run).and_raise(
          PromptEngine::OpenAiEvalsClient::RateLimitError, "Rate limit exceeded"
        )

        expect { runner.execute }.to raise_error(PromptEngine::OpenAiEvalsClient::RateLimitError)

        eval_run.reload
        expect(eval_run.status).to eq("failed")
        expect(eval_run.error_message).to eq("Rate limit exceeded")
      end

      it "handles polling timeouts" do
        allow(@mock_client).to receive(:create_eval).and_return({ "id" => "eval_123" })
        allow(@mock_client).to receive(:upload_file).and_return({ "id" => "file_123" })
        allow(@mock_client).to receive(:create_run).and_return({
          "id" => "run_123",
          "report_url" => "https://example.com/report"
        })

        # Simulate run that never completes
        allow(@mock_client).to receive(:get_run).and_return({ "status" => "running" })

        # Speed up test by stubbing sleep
        allow(runner).to receive(:sleep)

        runner.execute

        eval_run.reload
        expect(eval_run.status).to eq("failed")
        expect(eval_run.error_message).to eq("Timeout waiting for eval results")
      end
    end

    context "concurrent evaluations" do
      let(:eval_run1) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version) }
      let(:eval_run2) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version) }

      it "handles multiple simultaneous runs" do
        # Both runs should be independent
        expect(eval_run1.status).to eq("pending")
        expect(eval_run2.status).to eq("pending")

        # Update one without affecting the other
        eval_run1.update!(status: "running")
        expect(eval_run2.reload.status).to eq("pending")
      end
    end
  end

  describe "API key missing scenarios" do
    before do
      PromptEngine::Setting.instance.update!(openai_api_key: nil)
      allow(Rails.application.credentials).to receive(:dig).with(:openai, :api_key).and_return(nil)
    end

    it "provides clear error when trying to create client" do
      expect {
        PromptEngine::OpenAiEvalsClient.new
      }.to raise_error(
        PromptEngine::OpenAiEvalsClient::AuthenticationError,
        "OpenAI API key not configured"
      )
    end

    it "provides helpful error in controller" do
      eval_set = create(:eval_set, prompt: prompt)
      create(:test_case, eval_set: eval_set)

      # Simulate controller action
      eval_run = eval_set.eval_runs.create!(prompt_version: prompt_version)

      expect {
        PromptEngine::EvaluationRunner.new(eval_run).execute
      }.to raise_error(PromptEngine::OpenAiEvalsClient::AuthenticationError)
    end
  end

  describe "Large dataset handling" do
    let(:eval_set) { create(:eval_set, prompt: prompt) }

    context "with many test cases" do
      let!(:many_test_cases) do
        100.times.map do |i|
          create(:test_case,
            eval_set: eval_set,
            input_variables: { "index" => i.to_s },
            expected_output: "Output for test #{i}"
          )
        end
      end

      it "handles large test case sets" do
        expect(eval_set.test_cases.count).to eq(100)
        expect(eval_set.ready_to_run?).to be true
      end

      it "can paginate test cases efficiently" do
        # Test pagination
        page1 = eval_set.test_cases.limit(20).offset(0)
        page2 = eval_set.test_cases.limit(20).offset(20)

        expect(page1.count).to eq(20)
        expect(page2.count).to eq(20)
        expect(page1.first).not_to eq(page2.first)
      end
    end

    context "with many evaluation runs" do
      let!(:test_case) { create(:test_case, eval_set: eval_set) }

      let!(:many_runs) do
        50.times.map do |i|
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            created_at: i.days.ago
          )
        end
      end

      it "efficiently queries recent runs" do
        recent_runs = eval_set.eval_runs.order(created_at: :desc).limit(10)
        expect(recent_runs.count).to eq(10)
        expect(recent_runs.first.created_at).to be > recent_runs.last.created_at
      end

      it "calculates aggregate metrics efficiently" do
        # Should use SQL aggregation rather than loading all records
        total_passed = eval_set.eval_runs.where(status: 'completed').sum(:passed_count)
        total_tests = eval_set.eval_runs.where(status: 'completed').sum(:total_count)

        expect(total_passed).to be >= 0
        expect(total_tests).to be > 0
      end
    end
  end

  describe "Special characters and encoding" do
    let(:eval_set) { create(:eval_set, prompt: prompt) }

    it "handles unicode in test cases" do
      test_case = create(:test_case,
        eval_set: eval_set,
        input_variables: { "text" => "Hello 世界 🌍" },
        expected_output: "你好世界",
        description: "Unicode test with emoji 🎉"
      )

      expect(test_case).to be_valid
      expect(test_case.reload.input_variables["text"]).to eq("Hello 世界 🌍")
    end

    it "handles special characters in expected output" do
      test_case = create(:test_case,
        eval_set: eval_set,
        input_variables: { "code" => "function() { return 'test'; }" },
        expected_output: '{"result": "success", "data": null}',
        description: "JSON output test"
      )

      expect(test_case).to be_valid
      expect(test_case.expected_output).to include('"result"')
    end

    it "handles newlines and whitespace in outputs" do
      test_case = create(:test_case,
        eval_set: eval_set,
        input_variables: { "format" => "multi-line" },
        expected_output: "Line 1\nLine 2\n\tIndented line 3",
        description: "Multi-line output"
      )

      expect(test_case).to be_valid
      expect(test_case.expected_output).to include("\n")
      expect(test_case.expected_output).to include("\t")
    end
  end
end
