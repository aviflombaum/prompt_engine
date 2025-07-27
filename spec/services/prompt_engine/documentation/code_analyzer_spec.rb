require "rails_helper"

RSpec.describe PromptEngine::Documentation::CodeAnalyzer do
  let(:test_file_path) { Rails.root.join("tmp/test_model.rb") }
  let(:analyzer) { described_class.new(test_file_path) }

  before do
    FileUtils.mkdir_p(Rails.root.join("tmp"))
  end

  after do
    FileUtils.rm_f(test_file_path)
  end

  describe "#analyze" do
    context "with a model file" do
      before do
        File.write(test_file_path, <<~RUBY)
          module PromptEngine
            class TestModel < ApplicationRecord
              # Constants
              MAX_LENGTH = 1000
              STATUS_VALUES = %w[draft active archived].freeze

              # Associations
              belongs_to :user
              has_many :items, dependent: :destroy
              has_one :profile

              # Validations
              validates :name, presence: true, length: { maximum: 255 }
              validates :status, inclusion: { in: STATUS_VALUES }

              # Attributes
              attr_accessor :temporary_data
              attr_reader :calculated_value

              # Enums
              enum status: { draft: 0, active: 1, archived: 2 }

              # Includes
              include Searchable
              include Trackable

              def public_method(param1, param2 = nil)
                # Public method implementation
              end

              def another_public_method
                # Another public method
              end

              private

              def private_method
                # Private method implementation
              end
            end
          end
        RUBY
      end

      it "extracts the class name" do
        expect(analyzer.analyze[:class_name]).to eq("TestModel")
      end

      it "extracts the module name" do
        expect(analyzer.analyze[:module_name]).to eq("PromptEngine")
      end

      it "determines the file type" do
        allow(test_file_path).to receive(:to_s).and_return("app/models/test_model.rb")
        expect(analyzer.analyze[:type]).to eq("model")
      end

      it "extracts constants" do
        constants = analyzer.analyze[:constants]
        expect(constants).to include(
          { name: "MAX_LENGTH", value: "1000" },
          { name: "STATUS_VALUES", value: "%w[draft active archived].freeze" }
        )
      end

      it "extracts associations" do
        associations = analyzer.analyze[:associations]
        expect(associations).to include(
          { type: "belongs_to", name: "user", options: "" },
          { type: "has_many", name: "items", options: ", dependent: :destroy" },
          { type: "has_one", name: "profile", options: "" }
        )
      end

      it "extracts validations" do
        validations = analyzer.analyze[:validations]
        expect(validations).to include(
          { attribute: "name", validation: ", presence: true, length: { maximum: 255 }" },
          { attribute: "status", validation: ", inclusion: { in: STATUS_VALUES }" }
        )
      end

      it "extracts attributes" do
        attributes = analyzer.analyze[:attributes]
        expect(attributes).to include(
          { name: "temporary_data", type: "attribute", accessor: "attr_accessor" },
          { name: "calculated_value", type: "attribute", accessor: "attr_reader" },
          { name: "status", type: "enum", values: "{ draft: 0, active: 1, archived: 2 }" }
        )
      end

      it "extracts includes" do
        includes = analyzer.analyze[:includes]
        expect(includes).to include("Searchable", "Trackable")
      end

      it "extracts public methods" do
        methods = analyzer.analyze[:methods]
        public_methods = methods.select { |m| m[:visibility] == "public" }
        
        expect(public_methods).to include(
          hash_including(name: "public_method", parameters: "param1, param2 = nil", visibility: "public"),
          hash_including(name: "another_public_method", parameters: "", visibility: "public")
        )
      end

      it "extracts private methods" do
        methods = analyzer.analyze[:methods]
        private_methods = methods.select { |m| m[:visibility] == "private" }
        
        expect(private_methods).to include(
          hash_including(name: "private_method", parameters: "", visibility: "private")
        )
      end
    end

    context "with a controller file" do
      before do
        File.write(test_file_path, <<~RUBY)
          module PromptEngine
            class TestController < ApplicationController
              before_action :authenticate_user!
              before_action :set_resource, only: [:show, :edit, :update, :destroy]

              def index
                @resources = Resource.all
              end

              def show
                render json: @resource
              end

              def create(resource_params)
                @resource = Resource.new(resource_params)
                
                if @resource.save
                  redirect_to @resource
                else
                  render :new
                end
              end

              private

              def set_resource
                @resource = Resource.find(params[:id])
              end

              def resource_params
                params.require(:resource).permit(:name, :description)
              end
            end
          end
        RUBY
      end

      it "identifies controller type" do
        allow(test_file_path).to receive(:to_s).and_return("app/controllers/test_controller.rb")
        expect(analyzer.analyze[:type]).to eq("controller")
      end

      it "extracts controller methods" do
        methods = analyzer.analyze[:methods]
        expect(methods.map { |m| m[:name] }).to include("index", "show", "create", "set_resource", "resource_params")
      end
    end

    context "with a service file" do
      before do
        File.write(test_file_path, <<~RUBY)
          module PromptEngine
            class TestService
              attr_reader :user, :params

              def initialize(user, params = {})
                @user = user
                @params = params
              end

              def call
                validate_params!
                process_data
                send_notification
              end

              private

              def validate_params!
                raise ArgumentError, "Invalid params" unless params.valid?
              end

              def process_data
                # Processing logic
              end

              def send_notification
                # Notification logic
              end
            end
          end
        RUBY
      end

      it "identifies service type" do
        allow(test_file_path).to receive(:to_s).and_return("app/services/test_service.rb")
        expect(analyzer.analyze[:type]).to eq("service")
      end

      it "extracts initialize method" do
        methods = analyzer.analyze[:methods]
        expect(methods).to include(
          hash_including(name: "initialize", parameters: "user, params = {}", visibility: "public")
        )
      end
    end

    context "with schema information in comments" do
      before do
        File.write(test_file_path, <<~RUBY)
          # == Schema Information
          #
          # Table name: test_models
          #
          #  id         :bigint           not null, primary key
          #  name       :string(255)      not null
          #  status     :integer          default(0)
          #  created_at :datetime         not null
          #  updated_at :datetime         not null
          #
          module PromptEngine
            class TestModel < ApplicationRecord
            end
          end
        RUBY
      end

      it "extracts schema attributes" do
        attributes = analyzer.analyze[:attributes]
        expect(attributes).to include(
          { name: "id", type: "bigint" },
          { name: "name", type: "string(255)" },
          { name: "status", type: "integer" },
          { name: "created_at", type: "datetime" },
          { name: "updated_at", type: "datetime" }
        )
      end
    end

    context "with an empty file" do
      before do
        File.write(test_file_path, "")
      end

      it "returns empty analysis" do
        analysis = analyzer.analyze
        expect(analysis[:class_name]).to be_nil
        expect(analysis[:methods]).to be_empty
        expect(analysis[:associations]).to be_empty
      end
    end

    context "with syntax errors" do
      before do
        File.write(test_file_path, <<~RUBY)
          module PromptEngine
            class TestModel
              def broken_method(
                # Missing closing parenthesis
              end
            end
          end
        RUBY
      end

      it "still extracts what it can" do
        analysis = analyzer.analyze
        expect(analysis[:class_name]).to eq("TestModel")
        expect(analysis[:module_name]).to eq("PromptEngine")
      end
    end
  end

  describe "#find_line_number" do
    before do
      File.write(test_file_path, <<~RUBY)
        class TestModel
          def first_method
            # Line 3
          end

          def second_method
            # Line 7
          end
        end
      RUBY
    end

    it "finds the correct line number" do
      content = File.read(test_file_path)
      analyzer = described_class.new(test_file_path)
      
      # Access private method for testing
      line_number = analyzer.send(:find_line_number, "def first_method")
      expect(line_number).to eq(2)
      
      line_number = analyzer.send(:find_line_number, "def second_method")
      expect(line_number).to eq(6)
    end
  end
end