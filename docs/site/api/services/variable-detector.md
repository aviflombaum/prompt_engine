---
title: "Variable Detector"
layout: "docs"
parent: "api/services"
nav_order: "variabledetector"
---

# VariableDetector

Service object for variable detector operations.

## Purpose

This service encapsulates business logic for detecting and extracting variables from prompt templates.

## Public Interface

### call

**Parameters:** `content`

Performs call operation to extract variables from the given content.

### detect_variables

Performs detect variables operation to find all {{variable}} patterns in the content.

### infer_type

**Parameters:** `variable_name`

Performs infer type operation to determine the data type based on variable naming conventions.

## Usage

```ruby
service = PromptEngine::VariableDetector.new
result = service.call
```

## Example

```ruby
detector = PromptEngine::VariableDetector.new
variables = detector.detect_variables("Hello {{name}}, you are {{age}} years old")
# => ["name", "age"]

type = detector.infer_type("created_at")
# => :datetime
```