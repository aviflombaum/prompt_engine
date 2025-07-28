require "rails_helper"
require "ostruct"

RSpec.describe PromptEngine::Documentation::Generator do
  let(:output_dir) { Rails.root.join("tmp/test_docs") }
  let(:generator) { described_class.new(output_dir: output_dir) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_response) { OpenStruct.new(content: "# TestModel\n\nThis is the documentation for TestModel.") }

  before do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
    FileUtils.mkdir_p(output_dir)
    
    # Mock RubyLLM.chat
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
    
    # Mock credentials
    allow(Rails.application.credentials).to receive(:anthropic).and_return(
      OpenStruct.new(api_key: "test-key")
    )
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "#initialize" do
    it "sets the output directory" do
      expect(generator.output_dir).to eq(output_dir)
    end

    context "when no API key is configured" do
      before do
        allow(Rails.application.credentials).to receive(:anthropic).and_return(nil)
        allow(Rails.application.credentials).to receive(:openai).and_return(nil)
        # Temporarily clear environment variables
        @original_openai_key = ENV["OPENAI_API_KEY"]
        @original_anthropic_key = ENV["ANTHROPIC_API_KEY"]
        ENV["OPENAI_API_KEY"] = nil
        ENV["ANTHROPIC_API_KEY"] = nil
      end

      after do
        # Restore environment variables
        ENV["OPENAI_API_KEY"] = @original_openai_key
        ENV["ANTHROPIC_API_KEY"] = @original_anthropic_key
      end

      it "initializes without API configuration" do
        generator = described_class.new
        expect(generator.llm_client).to be_falsey
      end
    end
  end

  describe "#generate_all" do
    before do
      # Mock all generation methods
      allow(generator).to receive(:generate_index_page)
      allow(generator).to receive(:generate_getting_started)
      allow(generator).to receive(:generate_installation)
      allow(generator).to receive(:generate_configuration)
      allow(generator).to receive(:generate_model_docs)
      allow(generator).to receive(:generate_controller_docs)
      allow(generator).to receive(:generate_service_docs)
      allow(generator).to receive(:generate_guide_docs)
      allow(generator).to receive(:generate_reference_docs)
    end

    it "creates the output directory" do
      generator.generate_all
      expect(Dir.exist?(output_dir)).to be true
    end

    it "calls all generation methods" do
      expect(generator).to receive(:generate_index_page)
      expect(generator).to receive(:generate_getting_started)
      expect(generator).to receive(:generate_installation)
      expect(generator).to receive(:generate_configuration)
      expect(generator).to receive(:generate_model_docs)
      expect(generator).to receive(:generate_controller_docs)
      expect(generator).to receive(:generate_service_docs)
      expect(generator).to receive(:generate_guide_docs)
      expect(generator).to receive(:generate_reference_docs)
      
      generator.generate_all
    end
  end

  describe "#generate_model_docs" do
    let(:test_model_file) { Rails.root.join("app/models/prompt_engine/test_model.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(test_model_file))
      File.write(test_model_file, <<~RUBY)
        module PromptEngine
          class TestModel < ApplicationRecord
            validates :name, presence: true
          end
        end
      RUBY

      # Mocking is already set up in the before block
    end

    after do
      FileUtils.rm_f(test_model_file)
    end

    it "creates the models directory" do
      generator.generate_model_docs
      expect(Dir.exist?("#{output_dir}/api/models")).to be true
    end

    it "generates documentation for each model" do
      generator.generate_model_docs
      
      doc_file = "#{output_dir}/api/models/test-model.md"
      expect(File.exist?(doc_file)).to be true
      
      content = File.read(doc_file)
      expect(content).to include("title: \"Test Model\"")
      expect(content).to include("This is the documentation for TestModel")
    end

    it "generates models index page" do
      generator.generate_model_docs
      
      index_file = "#{output_dir}/api/models/index.md"
      expect(File.exist?(index_file)).to be true
      
      content = File.read(index_file)
      expect(content).to include("# Model Documentation")
      expect(content).to include("[TestModel](test-model.md)")
    end
  end

  describe "#generate_controller_docs" do
    let(:test_controller_file) { Rails.root.join("app/controllers/prompt_engine/test_controller.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(test_controller_file))
      File.write(test_controller_file, <<~RUBY)
        module PromptEngine
          class TestController < ApplicationController
            def index
              render json: { status: "ok" }
            end
          end
        end
      RUBY

      # Mocking is already set up in the before block
    end

    after do
      FileUtils.rm_f(test_controller_file)
    end

    it "creates the controllers directory" do
      generator.generate_controller_docs
      expect(Dir.exist?("#{output_dir}/api/controllers")).to be true
    end

    it "generates documentation for each controller" do
      generator.generate_controller_docs
      
      doc_file = "#{output_dir}/api/controllers/test.md"
      expect(File.exist?(doc_file)).to be true
      
      content = File.read(doc_file)
      expect(content).to include("title: \"Test API\"")
      expect(content).to include("API documentation for TestController")
    end
  end

  describe "#generate_service_docs" do
    let(:test_service_file) { Rails.root.join("app/services/prompt_engine/test_service.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(test_service_file))
      File.write(test_service_file, <<~RUBY)
        module PromptEngine
          class TestService
            def call
              # Service logic
            end
          end
        end
      RUBY

      # Mocking is already set up in the before block
    end

    after do
      FileUtils.rm_f(test_service_file)
    end

    it "creates the services directory" do
      generator.generate_service_docs
      expect(Dir.exist?("#{output_dir}/api/services")).to be true
    end

    it "skips CodeAnalyzer and Generator services" do
      # Create files for these services
      code_analyzer_file = Rails.root.join("app/services/prompt_engine/documentation/code_analyzer.rb")
      generator_file = Rails.root.join("app/services/prompt_engine/documentation/generator.rb")
      
      FileUtils.mkdir_p(File.dirname(code_analyzer_file))
      File.write(code_analyzer_file, "class CodeAnalyzer; end")
      File.write(generator_file, "class Generator; end")
      
      generator.generate_service_docs
      
      expect(File.exist?("#{output_dir}/api/services/code-analyzer.md")).to be false
      expect(File.exist?("#{output_dir}/api/services/generator.md")).to be false
      
      FileUtils.rm_f(code_analyzer_file)
      FileUtils.rm_f(generator_file)
    end
  end

  describe "#add_frontmatter" do
    it "adds frontmatter to content" do
      content = "# Test Content"
      metadata = { title: "Test Page", layout: "docs", nav_order: 1 }
      
      result = generator.send(:add_frontmatter, content, metadata)
      
      expect(result).to include("---")
      expect(result).to include('title: "Test Page"')
      expect(result).to include('layout: "docs"')
      expect(result).to include('nav_order: "1"')
      expect(result).to include("# Test Content")
    end
  end

  describe "#write_documentation" do
    it "writes content to file" do
      generator.send(:write_documentation, "test/page.md", "# Test Content")
      
      file_path = "#{output_dir}/test/page.md"
      expect(File.exist?(file_path)).to be true
      expect(File.read(file_path)).to eq("# Test Content")
    end

    it "creates parent directories" do
      generator.send(:write_documentation, "deep/nested/path/page.md", "# Content")
      
      expect(Dir.exist?("#{output_dir}/deep/nested/path")).to be true
    end
  end

  describe "#generate_index_page" do
    it "creates an index page with proper content" do
      generator.send(:generate_index_page)
      
      index_file = "#{output_dir}/index.md"
      expect(File.exist?(index_file)).to be true
      
      content = File.read(index_file)
      expect(content).to include("title: \"PromptEngine Documentation\"")
      expect(content).to include("# PromptEngine Documentation")
      expect(content).to include("## Quick Links")
      expect(content).to include("[Getting Started](getting-started.md)")
    end
  end

  describe "#generate_getting_started" do
    it "creates a getting started page" do
      generator.send(:generate_getting_started)
      
      file_path = "#{output_dir}/getting-started.md"
      expect(File.exist?(file_path)).to be true
      
      content = File.read(file_path)
      expect(content).to include("title: \"Getting Started\"")
      expect(content).to include("# Getting Started with PromptEngine")
      expect(content).to include("## Prerequisites")
      expect(content).to include("gem 'prompt_engine'")
    end
  end

  describe "#generate_installation" do

    before do
      # Mocking is already set up in the before block
    end

    it "creates an installation page using LLM" do
      generator.send(:generate_installation)
      
      file_path = "#{output_dir}/installation.md"
      expect(File.exist?(file_path)).to be true
      
      content = File.read(file_path)
      expect(content).to include("title: \"Installation\"")
      expect(content).to include("Detailed Installation Guide")
    end
  end

  describe "#generate_configuration" do
    it "creates a configuration page" do
      generator.send(:generate_configuration)
      
      file_path = "#{output_dir}/configuration.md"
      expect(File.exist?(file_path)).to be true
      
      content = File.read(file_path)
      expect(content).to include("title: \"Configuration\"")
      expect(content).to include("# Configuration")
      expect(content).to include("## API Credentials")
      expect(content).to include("rails credentials:edit")
    end
  end

  describe "prompt builders" do
    let(:analysis) do
      {
        class_name: "TestModel",
        module_name: "PromptEngine",
        raw_content: "class TestModel; end",
        associations: [{ type: "belongs_to", name: "user" }],
        validations: [{ attribute: "name", validation: "presence: true" }],
        attributes: [{ name: "name", type: "string" }],
        methods: [{ name: "test_method", parameters: "", visibility: "public" }]
      }
    end

    describe "#build_model_prompt" do
      it "builds a comprehensive model prompt" do
        prompt = generator.send(:build_model_prompt, analysis)
        
        expect(prompt).to include("Given this Ruby model code:")
        expect(prompt).to include("class TestModel; end")
        expect(prompt).to include("Class: TestModel")
        expect(prompt).to include("Module: PromptEngine")
        expect(prompt).to include("belongs_to")
        expect(prompt).to include("test_method")
      end
    end

    describe "#build_controller_prompt" do
      it "builds a comprehensive controller prompt" do
        prompt = generator.send(:build_controller_prompt, analysis)
        
        expect(prompt).to include("Given this Rails controller code:")
        expect(prompt).to include("class TestModel; end")
        expect(prompt).to include("Class: TestModel")
        expect(prompt).to include("test_method")
      end
    end

    describe "#build_service_prompt" do
      it "builds a comprehensive service prompt" do
        prompt = generator.send(:build_service_prompt, analysis)
        
        expect(prompt).to include("Given this service class:")
        expect(prompt).to include("class TestModel; end")
        expect(prompt).to include("Class: TestModel")
        expect(prompt).to include("test_method")
      end
    end
  end
end