---
title: "Application Record"
layout: "docs"
parent: "api/models"
nav_order: "applicationrecord"
---

# PromptEngine::ApplicationRecord

## Description

`PromptEngine::ApplicationRecord` serves as the abstract base class for all models in the `PromptEngine` module of a Rails application. By inheriting from `ActiveRecord::Base`, it provides ORM capabilities to its subclasses, allowing them to interact with the database. This class is marked as abstract, which means it is not meant to be instantiated directly but rather to be subclassed by other models. This setup helps in sharing common behavior among all models in the module, such as connection information, configurations, and common scopes or methods.

## Attributes

Since `ApplicationRecord` is an abstract class, it does not directly define any attributes. Attributes will be defined in the subclasses that inherit from `ApplicationRecord`. Here's a general structure of how attributes are typically listed, which applies to subclasses:

| Attribute | Type | Description |
|-----------|------|-------------|
| `id`      | Integer | Automatically generated primary key for the table. |
| `created_at` | DateTime | Automatically managed by ActiveRecord, stores the date and time when the record was created. |
| `updated_at` | DateTime | Automatically managed by ActiveRecord, stores the date and time when the record was last updated. |

## Associations

This class does not define any associations. Associations such as `has_many`, `belongs_to`, `has_one`, and `has_and_belongs_to_many` will be defined in the subclasses. Below is a generic example of how associations might be described:

- `has_many :children` - Defines a one-to-many relationship between this model and the `Child` model.

## Validations

`ApplicationRecord` does not include any validations. Validations are typically defined in the subclasses to enforce data integrity and business rules. Examples of common validations include:

- `validates :name, presence: true` - Ensures that the `name` attribute is present before saving the model.
- `validates :email, uniqueness: true` - Ensures that the `email` attribute is unique across all records in the table.

## Key Methods

This class itself does not define any methods beyond what ActiveRecord provides. However, custom methods would generally be defined in the subclasses. Here is an example of how a custom method might be documented:

```ruby
# Calculates and returns the number of days since the record was created
def days_since_created
  (Date.today - self.created_at.to_date).to_i
end
```

## Common Usage Patterns

As `ApplicationRecord` is an abstract class, it's primarily used as a superclass from which other models within the `PromptEngine` module inherit. This approach keeps the model code DRY (Don't Repeat Yourself) and organized. For example:

```ruby
module PromptEngine
  class User < ApplicationRecord
    # Model specific methods, validations, and associations go here
  end
end
```

## Important Notes or Caveats

- **Abstract Nature**: Since `ApplicationRecord` is abstract, attempting to instantiate it directly will raise an error. Always use it as a superclass.
- **Shared Behavior**: Any configuration or method added to `ApplicationRecord` will be shared across all inheriting classes. Make sure that shared behavior is applicable to all subclasses to avoid unexpected behaviors.
- **Maintenance**: Changes to this class can affect all models in the `PromptEngine` module, so modifications should be made cautiously and tested thoroughly.
