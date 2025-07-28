---
title: "Playground API"
layout: "docs"
parent: "api/controllers"
nav_order: "playground"
---

# API Documentation for PromptEngine::PlaygroundController

## Overview
The `PlaygroundController` within the `PromptEngine` module is responsible for interacting with and executing prompts in a playground environment. This controller allows users to view and execute prompts with custom parameters, facilitating testing and development of prompt-based systems.

## Authentication
This controller assumes authentication is managed upstream, possibly via `ApplicationController` from which it inherits. Ensure users are authenticated before accessing the endpoints described.

## Actions

### 1. Show Prompt
- **HTTP Method and Path:** `GET /prompt_engine/playground/:id`
- **Description:** Displays the parameters required for a specific prompt and general settings.
- **Parameters:**
  - `id` (required): The ID of the prompt to display.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK`: Successfully retrieved prompt details.
  - `404 Not Found`: No prompt found with the given ID.
- **Example Request:**
  ```bash
  curl -X GET "http://example.com/prompt_engine/playground/1"
  ```
- **Example Response:**
  ```html
  <!-- Rendered HTML showing prompt parameters and settings -->
  ```

### 2. Execute Prompt
- **HTTP Method and Path:** `POST /prompt_engine/playground/:id/execute`
- **Description:** Executes the prompt with given parameters and returns the result.
- **Parameters:**
  - `id` (required): The ID of the prompt to execute.
  - `provider` (required): The provider to use for execution.
  - `api_key` (required): API key for the provider.
  - `parameters` (optional): Custom parameters for the prompt in JSON format.
- **Response Format:** HTML (renders execution results or errors)
- **Status Codes:**
  - `200 OK`: Execution successful.
  - `400 Bad Request`: Invalid parameters or missing required information.
  - `500 Internal Server Error`: Errors during execution or issues with the provider.
- **Example Request:**
  ```bash
  curl -X POST "http://example.com/prompt_engine/playground/1/execute" \
       -H "Content-Type: application/json" \
       -d '{"provider": "ai_provider", "api_key": "secret_key", "parameters": {"name": "value"}}'
  ```
- **Example Response:**
  ```html
  <!-- Rendered HTML with execution results or error message -->
  ```

## Error Handling
Errors are handled by catching exceptions during the execution process. If an error occurs, the message is captured and rendered in the response. Common errors include API failures, parameter mismatches, or internal configuration issues, which are displayed to the user to aid troubleshooting.

For any issues not explicitly handled, a generic error message is presented, and it's recommended to check server logs for detailed diagnostic information.

