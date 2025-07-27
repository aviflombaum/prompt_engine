# Document Generation with AI

## Overview

This document outlines the design and implementation of an AI-powered documentation generation system for PromptEngine. The system uses RubyLLM to analyze the codebase and generate up-to-date markdown documentation compatible with Sitepress.

## Goals

1. **Automatic Documentation**: Generate comprehensive documentation from code analysis
2. **Sitepress Compatibility**: Output markdown files in the correct format for Sitepress
3. **AI-Powered Understanding**: Use LLM to understand code intent and generate human-readable docs
4. **Keep Documentation Current**: Re-generate docs as code changes
5. **Zero Manual Maintenance**: Documentation updates automatically with code changes

## Sitepress Markdown Format

Sitepress expects markdown files with:
- Frontmatter for metadata (title, layout, navigation)
- Standard markdown content
- Specific directory structure for navigation

Example format:
```markdown
---
title: "Getting Started with PromptEngine"
layout: "docs"
nav_order: 1
parent: "guides"
---

# Getting Started with PromptEngine

Content here...
```

## Architecture

### Components

1. **CodeAnalyzer Service**
   - Reads Ruby files and extracts metadata
   - Identifies models, controllers, services, and their relationships
   - Extracts comments, method signatures, and validations

2. **DocumentationGenerator Service**
   - Uses RubyLLM to generate human-readable documentation
   - Converts code analysis into markdown pages
   - Maintains consistent documentation structure

3. **Rake Task**
   - `prompt_engine:docs:generate` - Main task to generate all documentation
   - `prompt_engine:docs:generate:models` - Generate model documentation
   - `prompt_engine:docs:generate:api` - Generate API documentation
   - `prompt_engine:docs:generate:guides` - Generate usage guides

### Documentation Structure

```
docs/site/
├── index.md                    # Main documentation homepage
├── getting-started.md          # Quick start guide
├── installation.md             # Installation instructions
├── configuration.md            # Configuration guide
├── guides/
│   ├── index.md               # Guides overview
│   ├── basic-usage.md         # Basic usage patterns
│   ├── advanced-features.md   # Advanced features
│   └── best-practices.md      # Best practices
├── api/
│   ├── index.md               # API overview
│   ├── models/
│   │   ├── index.md           # Models overview
│   │   ├── prompt.md          # Prompt model docs
│   │   ├── prompt-version.md  # PromptVersion model docs
│   │   └── parameter.md       # Parameter model docs
│   ├── controllers/
│   │   ├── index.md           # Controllers overview
│   │   └── prompts.md         # Prompts controller docs
│   └── services/
│       ├── index.md           # Services overview
│       ├── variable-detector.md
│       └── playground-executor.md
├── reference/
│   ├── index.md               # Reference overview
│   ├── rake-tasks.md          # Available rake tasks
│   ├── configuration.md       # Configuration reference
│   └── changelog.md           # Auto-generated changelog
└── examples/
    ├── index.md               # Examples overview
    └── integration.md         # Integration examples
```

## Implementation Plan

### Phase 1: Core Infrastructure

1. Create `app/services/prompt_engine/documentation/code_analyzer.rb`
   - Parse Ruby files using Parser gem
   - Extract class/module information
   - Collect method signatures and documentation comments
   - Identify associations and validations

2. Create `app/services/prompt_engine/documentation/generator.rb`
   - Initialize RubyLLM client
   - Define prompts for different documentation types
   - Generate markdown with proper frontmatter
   - Ensure consistent formatting

3. Create base rake task structure
   - Main task that orchestrates generation
   - Sub-tasks for different documentation types
   - Progress reporting

### Phase 2: Model Documentation

Generate documentation for each model including:
- Class description and purpose
- Attributes with types and descriptions
- Associations and relationships
- Validations and constraints
- Key methods and their usage
- Example code snippets

### Phase 3: API Documentation

Generate documentation for controllers/endpoints:
- Endpoint paths and HTTP methods
- Required and optional parameters
- Response formats and status codes
- Authentication requirements
- Example requests and responses

### Phase 4: Service Documentation

Document service objects:
- Purpose and responsibility
- Input parameters
- Return values
- Usage examples
- Error handling

### Phase 5: Guides and Examples

Generate user-facing guides:
- Getting started guide from README and setup instructions
- Best practices from code patterns
- Integration examples from specs
- Troubleshooting from common errors

## Prompts for RubyLLM

### Model Documentation Prompt
```
You are a technical writer creating documentation for a Rails model.

Given this Ruby model code:
{code}

Generate comprehensive markdown documentation including:
1. A brief description of the model's purpose
2. Table of attributes with types and descriptions
3. List of associations with explanations
4. List of validations with business rules
5. Key methods with usage examples
6. Common usage patterns
7. Any important notes or caveats

Format the output as clean, readable markdown.
```

### API Documentation Prompt
```
You are a technical writer creating API documentation.

Given this Rails controller code:
{code}

Generate API documentation including:
1. Brief description of the controller's purpose
2. For each action:
   - HTTP method and path
   - Description
   - Parameters (required/optional)
   - Response format
   - Status codes
   - Example request/response
3. Authentication requirements
4. Error handling

Format as clean markdown with clear examples.
```

### Service Documentation Prompt
```
You are a technical writer documenting a service object.

Given this service class:
{code}

Generate documentation including:
1. Purpose and responsibility
2. Usage examples
3. Method documentation
4. Error scenarios
5. Best practices

Format as clean, readable markdown.
```

## Configuration

The documentation generator will support configuration via:

```ruby
# config/prompt_engine_docs.yml
prompt_engine_docs:
  output_dir: "docs/site"
  
  # LLM settings
  llm_provider: "anthropic"  # or "openai"
  llm_model: "claude-3-5-sonnet"
  
  # Documentation settings
  include_private_methods: false
  include_specs_as_examples: true
  
  # Sitepress settings
  default_layout: "docs"
  navigation_depth: 3
  
  # Custom prompts (optional)
  custom_prompts:
    model: "path/to/custom_model_prompt.txt"
```

## Usage

```bash
# Generate all documentation
bundle exec rake prompt_engine:docs:generate

# Generate specific types
bundle exec rake prompt_engine:docs:generate:models
bundle exec rake prompt_engine:docs:generate:api
bundle exec rake prompt_engine:docs:generate:guides

# Generate with custom output directory
bundle exec rake prompt_engine:docs:generate OUTPUT_DIR=docs/my-site

# Generate with verbose output
bundle exec rake prompt_engine:docs:generate VERBOSE=true
```

## Error Handling

- Gracefully handle LLM API failures with retries
- Skip files that can't be parsed
- Log warnings for missing documentation
- Validate markdown output before writing

## Testing

Create specs for:
- CodeAnalyzer parsing accuracy
- Generator output format
- Rake task execution
- Sitepress compatibility

## Future Enhancements

1. **Incremental Generation**: Only regenerate changed files
2. **Custom Templates**: Support custom markdown templates
3. **Multi-language**: Generate docs in multiple languages
4. **Version Comparison**: Show changes between versions
5. **Search Index**: Generate search index for documentation
6. **Diagram Generation**: Auto-generate ERD and flow diagrams
7. **API Playground**: Generate interactive API examples
8. **Cross-references**: Auto-link between related documentation