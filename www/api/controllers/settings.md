---
title: "Settings API"
layout: "docs"
parent: "api/controllers"
nav_order: "settings"
---

# PromptEngine::SettingsController API Documentation

## Overview
The `SettingsController` is part of the `PromptEngine` module and is responsible for managing application settings specific to API configurations. This controller handles the display and updates of settings like API keys for OpenAI and Anthropic.

This controller assumes there is a singleton model `Setting` that stores these configuration values.

## Actions

### 1. Edit Settings
- **HTTP Method and Path**: GET `/settings/edit`
- **Description**: Displays the form for editing application settings.
- **Parameters**: None
- **Response Format**: HTML (renders edit form)
- **Status Codes**:
  - `200 OK`: Successfully renders the edit form.
- **Example Request**:
  ```bash
  GET /settings/edit
  ```
- **Example Response**:
  ```html
  <!-- Rendered HTML form for editing settings -->
  ```

### 2. Update Settings
- **HTTP Method and Path**: PATCH `/settings`
- **Description**: Processes the submission of the settings form and updates the settings. If the settings are updated successfully, it redirects back to the edit form with a success notice. If the update fails, it re-renders the edit form with error messages.
- **Parameters**:
  - **Required**: `setting[openai_api_key]` (string), `setting[anthropic_api_key]` (string)
- **Response Format**: HTML
- **Status Codes**:
  - `302 Found`: Redirects to the settings edit page upon successful update.
  - `422 Unprocessable Entity`: Renders the edit page again with validation errors if the update fails.
- **Example Request**:
  ```bash
  PATCH /settings
  Content-Type: application/x-www-form-urlencoded
  Body: setting[openai_api_key]=newkey123&setting[anthropic_api_key]=newkey456
  ```
- **Example Response**:
  - Success:
    ```http
    HTTP/1.1 302 Found
    Location: /settings/edit
    ```
  - Failure:
    ```http
    HTTP/1.1 422 Unprocessable Entity
    <!-- Rendered HTML form with error messages -->
    ```

## Authentication Requirements
Access to these settings endpoints should be restricted to authenticated administrators only. Ensure that appropriate before actions are set for authentication and authorization in the `ApplicationController` or within this controller.

## Error Handling
Errors in the update process are handled by re-rendering the `edit` view with status `422 Unprocessable Entity`, along with displaying form-specific error messages. This helps the user correct the inputs directly from the form.

**Note**: Ensure proper handling of unauthenticated access and any other exceptions that might arise due to operational issues, such as database downtime, through global exception handlers or specific rescue actions in the controller.
