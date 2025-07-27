namespace :prompt_engine do
  namespace :docs do
    desc "Generate documentation using mock generator (no LLM required)"
    task generate_mock: :environment do
      output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
      verbose = ENV["VERBOSE"] == "true"
      
      puts "Generating mock documentation (no LLM required)..."
      puts "Output directory: #{output_dir}" if verbose
      
      generator = PromptEngine::Documentation::MockGenerator.new(output_dir: output_dir)
      
      begin
        generator.generate_all
        puts "\n✅ Mock documentation generated successfully!"
        puts "View documentation in: #{output_dir}"
      rescue => e
        puts "\n❌ Error generating documentation: #{e.message}"
        puts e.backtrace if verbose
        exit 1
      end
    end
    desc "Generate all documentation"
    task generate: :environment do
      output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
      verbose = ENV["VERBOSE"] == "true"
      
      puts "Generating PromptEngine documentation..."
      puts "Output directory: #{output_dir}" if verbose
      
      generator = PromptEngine::Documentation::Generator.new(output_dir: output_dir)
      
      begin
        generator.generate_all
        puts "\n✅ Documentation generated successfully!"
        puts "View documentation in: #{output_dir}"
      rescue => e
        puts "\n❌ Error generating documentation: #{e.message}"
        puts e.backtrace if verbose
        exit 1
      end
    end

    namespace :generate do
      desc "Generate model documentation"
      task models: :environment do
        output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
        verbose = ENV["VERBOSE"] == "true"
        
        puts "Generating model documentation..."
        
        generator = PromptEngine::Documentation::Generator.new(output_dir: output_dir)
        
        begin
          generator.generate_model_docs
          puts "✅ Model documentation generated!"
        rescue => e
          puts "❌ Error: #{e.message}"
          puts e.backtrace if verbose
          exit 1
        end
      end

      desc "Generate API/controller documentation"
      task api: :environment do
        output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
        verbose = ENV["VERBOSE"] == "true"
        
        puts "Generating API documentation..."
        
        generator = PromptEngine::Documentation::Generator.new(output_dir: output_dir)
        
        begin
          generator.generate_controller_docs
          puts "✅ API documentation generated!"
        rescue => e
          puts "❌ Error: #{e.message}"
          puts e.backtrace if verbose
          exit 1
        end
      end

      desc "Generate service documentation"
      task services: :environment do
        output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
        verbose = ENV["VERBOSE"] == "true"
        
        puts "Generating service documentation..."
        
        generator = PromptEngine::Documentation::Generator.new(output_dir: output_dir)
        
        begin
          generator.generate_service_docs
          puts "✅ Service documentation generated!"
        rescue => e
          puts "❌ Error: #{e.message}"
          puts e.backtrace if verbose
          exit 1
        end
      end

      desc "Generate guides and tutorials"
      task guides: :environment do
        output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
        verbose = ENV["VERBOSE"] == "true"
        
        puts "Generating guides..."
        
        generator = PromptEngine::Documentation::Generator.new(output_dir: output_dir)
        
        begin
          generator.generate_guide_docs
          puts "✅ Guides generated!"
        rescue => e
          puts "❌ Error: #{e.message}"
          puts e.backtrace if verbose
          exit 1
        end
      end
    end

    desc "Clean generated documentation"
    task clean: :environment do
      output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
      
      if Dir.exist?(output_dir)
        puts "Cleaning documentation directory: #{output_dir}"
        FileUtils.rm_rf(output_dir)
        puts "✅ Documentation cleaned!"
      else
        puts "Documentation directory does not exist: #{output_dir}"
      end
    end

    desc "Validate generated documentation"
    task validate: :environment do
      output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
      
      puts "Validating documentation..."
      
      errors = []
      
      # Check for required files
      required_files = %w[
        index.md
        getting-started.md
        installation.md
        configuration.md
      ]
      
      required_files.each do |file|
        path = File.join(output_dir, file)
        unless File.exist?(path)
          errors << "Missing required file: #{file}"
        end
      end
      
      # Validate markdown files
      Dir.glob("#{output_dir}/**/*.md").each do |file|
        content = File.read(file)
        
        # Check for frontmatter
        unless content.start_with?("---")
          errors << "Missing frontmatter: #{file}"
        end
        
        # Check for title in frontmatter
        unless content.match?(/^title:\s*.+$/m)
          errors << "Missing title in frontmatter: #{file}"
        end
      end
      
      if errors.empty?
        puts "✅ Documentation is valid!"
      else
        puts "❌ Documentation validation failed:"
        errors.each { |error| puts "  - #{error}" }
        exit 1
      end
    end

    desc "Preview documentation structure"
    task preview: :environment do
      output_dir = ENV["OUTPUT_DIR"] || Rails.root.join("docs/site")
      
      puts "Documentation structure:"
      puts ""
      
      if Dir.exist?(output_dir)
        tree_output = `find #{output_dir} -name "*.md" | sort | sed 's|#{output_dir}/||'`
        puts tree_output
      else
        puts "Documentation not generated yet. Run `rake prompt_engine:docs:generate` first."
      end
    end
  end
end