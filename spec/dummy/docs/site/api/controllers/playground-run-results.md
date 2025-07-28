---
title: "PlaygroundRunResults API"
layout: "docs"
parent: "api/controllers"
nav_order: "playgroundrunresults"
---

# PlaygroundRunResultsController API Documentation

The `PlaygroundRunResultsController` is part of the `PromptEngine` module in a Rails application. This controller handles retrieving results of playground runs, which are essentially test runs of various prompt configurations and their versions.

## Authentication
Currently, the controller does not explicitly handle authentication. It is assumed that authentication and authorization are managed by the surrounding application infrastructure or through other parts of the application.

## Actions

### Index (List Playground Run Results)
- **HTTP Method and Path:** `GET /prompt_engine/playground_run_results`
- **Description:** Fetches a list of playground run results, optionally filtered by prompt or prompt version.
- **Parameters:**
  - `prompt_id` (optional): Filter results by prompt ID.
  - `version_id` (optional): Filter results by specific version ID of a prompt.
- **Response Format:** JSON
- **Status Codes:**
  - `200 OK` on successful retrieval.
- **Example Request:**
  - To fetch all results: `GET /prompt_engine/playground_run_results`
  - To fetch results for a specific prompt: `GET /prompt_engine/playground_run_results?prompt_id=123`
  - To fetch results for a specific version: `GET /prompt_engine/playground_run_results?version_id=456`
- **Example Response:**
  ```json
  [
    {
      "id": 1,
      "result_data": "Example result data",
      "created_at": "2023-12-01T12:00:00Z",
      "prompt_version": {
        "id": 10,
        "version_number": "1.0",
        "prompt_id": 123
      }
    }
  ]
  ```

### Show (Get a Single Playground Run Result)
- **HTTP Method and Path:** `GET /prompt_engine/playground_run_results/:id`
- **Description:** Retrieves detailed information about a specific playground run result.
- **Parameters:** None beyond the ID specified in the URL path.
- **Response Format:** JSON
- **Status Codes:**
  - `200 OK` on successful retrieval.
  - `404 Not Found` if the specified result does not exist.
- **Example Request:** `GET /prompt_engine/playground_run_results/1`
- **Example Response:**
  ```json
  {
    "id": 1,
    "result_data": "Detailed result data",
    "created_at": "2023-12-01T12:00:00Z",
    "prompt_version": {
      "id": 10,
      "version_number": "1.0",
      "prompt_id": 123
    }
  }
  ```

## Error Handling
Errors are typically handled by HTTP status codes:
- **404 Not Found:** Returned if a specific playground run result is requested but not found.
- **500 Internal Server Error:** General catch-all for server-side errors or exceptions.

For a robust API, consider implementing additional error handling and reporting mechanisms to provide more detailed error information to the clients, especially for validation errors or access denied scenarios.
