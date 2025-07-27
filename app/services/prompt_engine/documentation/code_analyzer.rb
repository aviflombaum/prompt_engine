module PromptEngine
  module Documentation
    class CodeAnalyzer
      attr_reader :file_path, :content

      def initialize(file_path)
        @file_path = file_path
        @content = File.read(file_path)
      end

      def analyze
        {
          file_path: file_path,
          class_name: extract_class_name,
          module_name: extract_module_name,
          type: determine_type,
          methods: extract_methods,
          associations: extract_associations,
          validations: extract_validations,
          attributes: extract_attributes,
          constants: extract_constants,
          includes: extract_includes,
          raw_content: content
        }
      end

      private

      def extract_class_name
        match = content.match(/class\s+(\w+)/)
        match ? match[1] : nil
      end

      def extract_module_name
        modules = content.scan(/module\s+(\w+)/).flatten
        modules.empty? ? nil : modules.join("::")
      end

      def determine_type
        return "model" if file_path.include?("app/models/")
        return "controller" if file_path.include?("app/controllers/")
        return "service" if file_path.include?("app/services/")
        return "job" if file_path.include?("app/jobs/")
        return "mailer" if file_path.include?("app/mailers/")
        "other"
      end

      def extract_methods
        methods = []
        
        # Extract public methods
        public_section = content.split(/^\s*private\s*$/)[0]
        public_section.scan(/def\s+(\w+)(\([^)]*\))?/) do |name, params|
          methods << {
            name: name,
            parameters: clean_parameters(params),
            visibility: "public",
            line: find_line_number("def #{name}")
          }
        end

        # Extract private methods
        if content.include?("private")
          private_section = content.split(/^\s*private\s*$/)[1]
          private_section&.scan(/def\s+(\w+)(\([^)]*\))?/) do |name, params|
            methods << {
              name: name,
              parameters: clean_parameters(params),
              visibility: "private",
              line: find_line_number("def #{name}")
            }
          end
        end

        methods
      end

      def extract_associations
        associations = []
        
        # Rails associations
        %w[belongs_to has_many has_one has_and_belongs_to_many].each do |assoc_type|
          content.scan(/#{assoc_type}\s+:(\w+)([^,\n]*)/) do |name, options|
            associations << {
              type: assoc_type,
              name: name,
              options: options.strip
            }
          end
        end

        associations
      end

      def extract_validations
        validations = []
        
        # Extract validates statements
        content.scan(/validates?\s+:(\w+)([^,\n]+)/) do |attribute, validation|
          validations << {
            attribute: attribute,
            validation: validation.strip
          }
        end

        validations
      end

      def extract_attributes
        attributes = []
        
        # For models, try to find schema information in comments
        schema_match = content.match(/# == Schema Information(.*?)#\s*$/m)
        if schema_match
          schema_match[1].scan(/#\s*(\w+)\s*:(\w+)/) do |name, type|
            next if name == "Table" || name == "Schema"
            attributes << { name: name, type: type }
          end
        end

        # Also look for attr_accessor, attr_reader, attr_writer
        %w[attr_accessor attr_reader attr_writer].each do |attr_type|
          content.scan(/#{attr_type}\s+(:\w+(?:\s*,\s*:\w+)*)/) do |attrs|
            attrs[0].split(",").each do |attr|
              attr_name = attr.strip.gsub(/^:/, "")
              attributes << { name: attr_name, type: "attribute", accessor: attr_type }
            end
          end
        end

        # Look for ActiveRecord enums
        content.scan(/enum\s+(\w+):\s*{([^}]+)}/) do |name, values|
          attributes << { name: name, type: "enum", values: values.strip }
        end

        attributes
      end

      def extract_constants
        constants = []
        content.scan(/^\s*([A-Z_]+)\s*=\s*(.+)$/) do |name, value|
          constants << { name: name, value: value.strip }
        end
        constants
      end

      def extract_includes
        includes = []
        content.scan(/include\s+(\w+(?:::\w+)*)/) do |module_name|
          includes << module_name[0]
        end
        includes
      end

      def clean_parameters(params)
        return "" unless params
        params.gsub(/[()]/, "").strip
      end

      def find_line_number(text)
        lines = content.split("\n")
        lines.each_with_index do |line, index|
          return index + 1 if line.include?(text)
        end
        nil
      end
    end
  end
end