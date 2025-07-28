---
title: "Prompts API"
layout: "docs"
parent: "api/controllers"
nav_order: "prompts"
---

# PromptEngine::PromptsController

The `PromptsController` manages the CRUD operations for `Prompt` objects within the `PromptEngine` module. It handles the listing, creation, updating, display, and deletion of prompts, along with managing associated evaluation data and test runs.

## Authentication Requirements

Authentication and authorization mechanisms are not explicitly shown in the provided code. You should ensure that appropriate authentication checks are implemented to protect the data and restrict access to authorized users only.

## Error Handling

Errors in operations such as create and update are handled by rendering the respective form (`new` or `edit`) with a status of `unprocessable_entity` (HTTP 422). This indicates that the server understands the content type of the request entity, and the syntax of the request entity is correct, but it was unable to process the contained instructions.

## Actions

### Index
- **HTTP Method and Path**: `GET /prompts`
- **Description**: Retrieves a list of all prompts, sorted by name.
- **Parameters**: None
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved list of prompts.
- **Example Request**: `GET /prompts`
- **Example Response**:
  ```json
  [
    {
      "id": 1,
      "name": "Example Prompt",
      "slug": "example-prompt"
    },
    {
      "id": 2,
      "name": "Another Prompt",
      "slug": "another-prompt"
    }
  ]
  ```

### Show
- **HTTP Method and Path**: `GET /prompts/:id`
- **Description**: Displays detailed information about a prompt, including recent test runs and evaluation data.
- **Parameters**: 
  - `id` (required): The ID of the prompt.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved prompt details.
  - `404 Not Found`: Prompt with the specified ID does not exist.
- **Example Request**: `GET /prompts/1`
- **Example Response**:
  ```json
  {
    "prompt": {
      "id": 1,
      "name": "Example Prompt",
      "description": "Detailed description of the prompt."
    },
    "recent_test_runs": [
      {
        "result_id": 101,
        "status": "Success"
      }
    ],
    "evaluation_data": {
      "recent_eval_runs": [
        {
          "run_id": 201,
          "outcome": "Passed"
        }
      ]
    }
  }
  ```

### New
- **HTTP Method and Path**: `GET /prompts/new`
- **Description**: Returns a form for creating a new prompt.
- **Parameters**: None
- **Response Format**: HTML
- **Status Codes**:
  - `200 OK`: Successfully retrieved the form.

### Create
- **HTTP Method and Path**: `POST /prompts`
- **Description**: Creates a new prompt based on provided parameters.
- **Parameters**:
  - `prompt[name]` (required)
  - `prompt[slug]` (required)
  - `prompt[description]` (optional)
  - `prompt[content]` (optional)
  - `prompt[system_message]` (optional)
  - `prompt[model]` (optional)
  - `prompt[temperature]` (optional)
  - `prompt[max_tokens]` (optional)
  - `prompt[status]` (optional)
  - `prompt[parameters_attributes]` (optional): Array of nested parameter attributes.
- **Response Format**: Redirection
- **Status Codes**:
  - `302 Found`: Redirect to the show page of the newly created prompt with a success notice.
  - `422 Unprocessable Entity`: Failed to create a prompt due to validation errors.
- **Example Request**:
  ```http
  POST /prompts
  Content-Type: application/json
  {
    "prompt": {
      "name": "New Prompt",
      "slug": "new-prompt",
      "description": "Description of the new prompt."
    }
  }
  ```

### Edit
- **HTTP Method and Path**: `GET /prompts/:id/edit`
- **Description**: Returns a form for editing an existing prompt.
- **Parameters**:
  - `id` (required): The ID of the prompt.
- **Response Format**: HTML
- **Status Codes**:
  - `200 OK`: Successfully retrieved the edit form.
  - `404 Not Found`: Prompt with the specified ID does not exist.

### Update
- **HTTP Method and Path**: `PATCH /prompts/:id`
- **Description**: Updates an existing prompt based on provided parameters.
- **Parameters**:
  - Same as in the `create` action, along with the prompt ID.
- **Response Format**: Redirection
- **Status Codes**:
  - `302 Found`: Redirect to the show page of the updated prompt with a success notice.
  - `422 Unprocessable Entity`: Failed to update the prompt due to validation errors.
- **Example Request**:
  ```http
  PATCH /prompts/1
  Content-Type: application/json
  {
    "prompt": {
      "description": "Updated description of the prompt."
    }
  }
  ```

### Destroy
- **HTTP Method and Path**: `DELETE /prompts/:id`
- **Description**: Deletes a specific prompt.
- **Parameters**:
  - `id` (required): The ID of the prompt.
- **Response Format**: Redirection
- **Status Codes**:
  - `302 Found`: Redirect to the index page with a success notice.
  - `404 Not Found`: Prompt with the specified ID does not exist.
- **Example Request**: `DELETE /prompts/1`
