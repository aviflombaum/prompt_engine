---
title: "Application API"
layout: "docs"
parent: "api/controllers"
nav_order: "application"
---

# PromptEngine::ApplicationController

## Overview

The `ApplicationController` within the `PromptEngine` module serves as the base controller for all other controllers in the PromptEngine engine. This controller includes basic configurations and setups that are common across the engine, such as authentication mechanisms provided by `PromptEngine::Authentication`. This controller ensures that any customization needed by the host application can be implemented using the ActiveSupport hook `:prompt_engine_application_controller`.

## Authentication

The `ApplicationController` includes the `PromptEngine::Authentication` module, which is responsible for handling the authentication logic. All controllers inheriting from `ApplicationController` are expected to have authentication checks unless explicitly bypassed.

## Error Handling

Error handling in the `ApplicationController` should be implemented to manage common HTTP errors such as 401 (Unauthorized) or 404 (Not Found). These errors should be handled gracefully, providing clear error messages and, if applicable, a path for resolution.

## Controller Actions

The `ApplicationController` does not define any specific actions as it serves as a base controller. Specific actions should be defined in the controllers inheriting from `ApplicationController`. Below is a template that can be used to document actions in inheriting controllers:

### Action Name

- **HTTP Method and Path**: `GET /example_path`
- **Description**: Briefly describes what the action does.
- **Parameters**:
  - `param1` (required): Description of param1.
  - `param2` (optional, default: value): Description of param2.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved data.
  - `400 Bad Request`: Issues with client's request.
  - `401 Unauthorized`: Authentication error.
- **Example Request**:
  ```bash
  curl -X GET "http://example.com/api/example_path?param1=value1" -H "Authorization: Bearer <token>"
  ```
- **Example Response**:
  ```json
  {
    "data": "Example data"
  }
  ```

## Customization

Customization of the `ApplicationController` can be done by using the ActiveSupport hook `:prompt_engine_application_controller`. This allows the host application to add or override configurations and behaviors in a clean and maintainable way.

## Conclusion

This documentation covers the foundational aspects of the `ApplicationController` in the `PromptEngine` module. Since it acts primarily as a base controller, it is crucial for developers to extend its functionalities in child controllers specific to their application's needs while maintaining the authentication and error handling strategies defined here.
