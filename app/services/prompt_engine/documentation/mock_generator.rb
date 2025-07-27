module PromptEngine
  module Documentation
    # Simple documentation generator that doesn't require LLM
    # Used for testing and proof of concept
    class MockGenerator < Generator
      def initialize(output_dir: "docs/site")
        @output_dir = output_dir
        @llm_client = nil # Don't need LLM for mock generation
      end

      private

      def generate_model_documentation(analysis)
        content = generate_mock_model_doc(analysis)
        
        frontmatter = {
          title: analysis[:class_name].titleize,
          layout: "docs",
          parent: "api/models",
          nav_order: analysis[:class_name].downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def generate_controller_documentation(analysis)
        content = generate_mock_controller_doc(analysis)
        
        controller_name = analysis[:class_name].gsub("Controller", "")
        frontmatter = {
          title: "#{controller_name} API",
          layout: "docs",
          parent: "api/controllers",
          nav_order: controller_name.downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def generate_service_documentation(analysis)
        content = generate_mock_service_doc(analysis)
        
        frontmatter = {
          title: analysis[:class_name].titleize,
          layout: "docs",
          parent: "api/services",
          nav_order: analysis[:class_name].downcase
        }
        
        add_frontmatter(content, frontmatter)
      end

      def generate_mock_model_doc(analysis)
        doc = "# #{analysis[:class_name]}\n\n"
        doc += "Model class for managing #{analysis[:class_name].underscore.humanize.downcase} records.\n\n"
        
        if analysis[:attributes].any?
          doc += "## Attributes\n\n"
          doc += "| Name | Type | Description |\n"
          doc += "|------|------|-------------|\n"
          analysis[:attributes].each do |attr|
            doc += "| #{attr[:name]} | #{attr[:type]} | #{humanize_attribute(attr[:name])} |\n"
          end
          doc += "\n"
        end
        
        if analysis[:associations].any?
          doc += "## Associations\n\n"
          analysis[:associations].each do |assoc|
            doc += "- **#{assoc[:type].humanize}** `:#{assoc[:name]}`"
            doc += " - #{assoc[:options]}" if assoc[:options].present?
            doc += "\n"
          end
          doc += "\n"
        end
        
        if analysis[:validations].any?
          doc += "## Validations\n\n"
          analysis[:validations].each do |validation|
            doc += "- `#{validation[:attribute]}` #{validation[:validation]}\n"
          end
          doc += "\n"
        end
        
        if analysis[:methods].any?
          public_methods = analysis[:methods].select { |m| m[:visibility] == "public" }
          if public_methods.any?
            doc += "## Public Methods\n\n"
            public_methods.each do |method|
              doc += "### #{method[:name]}\n\n"
              doc += "```ruby\n"
              doc += "def #{method[:name]}#{method[:parameters].present? ? "(#{method[:parameters]})" : ""}\n"
              doc += "  # Method implementation\n"
              doc += "end\n"
              doc += "```\n\n"
            end
          end
        end
        
        doc += "## Usage Example\n\n"
        doc += "```ruby\n"
        doc += "#{analysis[:class_name].underscore} = #{analysis[:class_name]}.new\n"
        doc += "# Add your usage example here\n"
        doc += "```\n"
        
        doc
      end

      def generate_mock_controller_doc(analysis)
        controller_name = analysis[:class_name].gsub("Controller", "")
        doc = "# #{controller_name} API\n\n"
        doc += "Handles API endpoints for #{controller_name.underscore.humanize.downcase} resources.\n\n"
        
        doc += "## Endpoints\n\n"
        
        analysis[:methods].each do |method|
          next if method[:visibility] == "private"
          
          case method[:name]
          when "index"
            doc += "### GET /prompt_engine/#{controller_name.underscore.pluralize}\n\n"
            doc += "Returns a list of all #{controller_name.underscore.humanize.downcase} resources.\n\n"
          when "show"
            doc += "### GET /prompt_engine/#{controller_name.underscore.pluralize}/:id\n\n"
            doc += "Returns a specific #{controller_name.underscore.humanize.downcase} resource.\n\n"
          when "create"
            doc += "### POST /prompt_engine/#{controller_name.underscore.pluralize}\n\n"
            doc += "Creates a new #{controller_name.underscore.humanize.downcase} resource.\n\n"
          when "update"
            doc += "### PATCH /prompt_engine/#{controller_name.underscore.pluralize}/:id\n\n"
            doc += "Updates an existing #{controller_name.underscore.humanize.downcase} resource.\n\n"
          when "destroy"
            doc += "### DELETE /prompt_engine/#{controller_name.underscore.pluralize}/:id\n\n"
            doc += "Deletes a #{controller_name.underscore.humanize.downcase} resource.\n\n"
          else
            doc += "### #{method[:name].upcase} /prompt_engine/#{controller_name.underscore.pluralize}/#{method[:name]}\n\n"
            doc += "Custom endpoint: #{method[:name]}.\n\n"
          end
          
          doc += "**Response Format:** JSON\n\n"
        end
        
        doc
      end

      def generate_mock_service_doc(analysis)
        doc = "# #{analysis[:class_name]}\n\n"
        doc += "Service object for #{analysis[:class_name].underscore.humanize.downcase} operations.\n\n"
        
        doc += "## Purpose\n\n"
        doc += "This service encapsulates business logic for #{analysis[:class_name].underscore.humanize.downcase}.\n\n"
        
        if analysis[:methods].any?
          public_methods = analysis[:methods].select { |m| m[:visibility] == "public" }
          if public_methods.any?
            doc += "## Public Interface\n\n"
            public_methods.each do |method|
              doc += "### #{method[:name]}\n\n"
              if method[:parameters].present?
                doc += "**Parameters:** `#{method[:parameters]}`\n\n"
              end
              doc += "Performs #{method[:name].humanize.downcase} operation.\n\n"
            end
          end
        end
        
        doc += "## Usage\n\n"
        doc += "```ruby\n"
        doc += "service = #{analysis[:module_name]}::#{analysis[:class_name]}.new\n"
        doc += "result = service.call\n"
        doc += "```\n"
        
        doc
      end

      def humanize_attribute(name)
        case name
        when "id"
          "Unique identifier"
        when "created_at"
          "Timestamp of creation"
        when "updated_at"
          "Timestamp of last update"
        when /_id$/
          "Foreign key for #{name.gsub(/_id$/, '').humanize.downcase}"
        else
          name.humanize
        end
      end
    end
  end
end