---
title: "Prompt"
layout: "docs"
parent: "api/models"
nav_order: "prompt"
---

# Prompt

Model class for managing prompt records.

## Attributes

| Name | Type | Description |
|------|------|-------------|
| id | bigint | Unique identifier |
| name | string | Name |
| content | text | Content |
| status | integer | Status |
| system_message | text | System message |
| model_config | jsonb | Model config |
| version | integer | Version |
| created_at | datetime | Timestamp of creation |
| updated_at | datetime | Timestamp of last update |

## Associations

- **Has many** `:prompt_versions`
- **Has many** `:parameters` - , dependent: :destroy

## Validations

- `name` , presence: true, uniqueness: true
- `content` , presence: true
- `status` , presence: true

## Public Methods

### render

```ruby
def render(variables: {})
  # Method implementation
end
```

### active?

```ruby
def active?
  # Method implementation
end
```

### create_version!

```ruby
def create_version!
  # Method implementation
end
```

### latest_version

```ruby
def latest_version
  # Method implementation
end
```

## Usage Example

```ruby
prompt = Prompt.new
# Add your usage example here
```