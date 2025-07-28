---
title: "Base API"
layout: "docs"
parent: "api/controllers"
nav_order: "base"
---

# PromptEngine::Admin::BaseController

The `BaseController` within the `PromptEngine::Admin` module serves as a foundational controller for all administrative controllers in the PromptEngine application. This controller sets a specific layout for the admin panel and ensures that all derived controllers inherit common behaviors, such as authentication and authorization checks specific to admin users.

## Controller Overview

- **Module:** `PromptEngine::Admin`
- **Class:** `BaseController`
- **Inheritance:** Inherits from `ApplicationController`
- **Layout:** Uses the `prompt_engine/admin` layout for rendering views

## Actions

The `BaseController` does not define any actions itself. It is intended to be subclassed by other controllers that will define their own actions.

## Authentication Requirements

All actions in any controller inheriting from `BaseController` are expected to require administrator authentication. Ensure that a before_action callback is set up in the `BaseController` or in the controllers inheriting from it to check for the admin user's authentication status.

```ruby
before_action :authenticate_admin!
```

## Error Handling

Errors within the `BaseController` or its subclasses should be handled gracefully, providing feedback suitable for an administrator. Common errors include unauthorized access and resource not found:

- **Unauthorized Access (401 Unauthorized):** Occurs if an unauthenticated user attempts to access any admin-specific actions.
- **Resource Not Found (404 Not Found):** Should be returned when an admin tries to access a non-existent resource.

### Example Error Response

```json
{
  "error": "Unauthorized",
  "message": "You must be logged in as an administrator to access this resource."
}
```

## Example Usage

Since the `BaseController` does not contain actions, below is an example of how a derived controller might look:

```ruby
module PromptEngine
  module Admin
    class UsersController < BaseController
      def index
        @users = User.all
        render json: @users
      end
    end
  end
end
```

### Example Request to Derived Controller Action

**Request**

```http
GET /admin/users HTTP/1.1
Host: example.com
Authorization: Bearer {token}
```

**Response**

```json
[
  {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  },
  {
    "id": 2,
    "username": "user2",
    "email": "user2@example.com"
  }
]
```

## Notes

- It is crucial to ensure that the `authenticate_admin!` method is defined and properly checks the authentication and authorization status of the user.
- Response formats and status codes might vary based on specific actions defined in the controllers inheriting from `BaseController`.
