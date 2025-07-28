---
title: "EvalRuns API"
layout: "docs"
parent: "api/controllers"
nav_order: "evalruns"
---

# PromptEngine::EvalRunsController API Documentation

## Overview

The `EvalRunsController` within the `PromptEngine` module is responsible for handling operations related to evaluation runs of prompts within the administrative interface. Specifically, this controller facilitates the display of evaluation run details.

## Actions

### `show`

- **HTTP Method and Path**: `GET /prompt_engine/prompts/:prompt_id/eval_runs/:id`
- **Description**: Retrieves and displays the aggregate results of a specific evaluation run associated with a given prompt. Note that in the current version (MVP), only aggregated data from OpenAI is displayed without individual evaluation results.
- **Parameters**:
  - `prompt_id` (required): The ID of the prompt associated with the evaluation run.
  - `id` (required): The ID of the evaluation run to display.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved the evaluation run details.
  - `404 Not Found`: Either the prompt or the evaluation run with the specified IDs does not exist.
- **Example Request**:
  ```bash
  curl -X GET "http://example.com/prompt_engine/prompts/123/eval_runs/456"
  ```
- **Example Response**:
  ```json
  {
    "id": 456,
    "prompt_id": 123,
    "summary": "Overall performance metrics and aggregated data from OpenAI."
  }
  ```

## Authentication Requirements

- This controller requires user authentication. Users must be logged in to access the evaluation runs. It is assumed that proper authentication and authorization checks are handled elsewhere in the application.

## Error Handling

Errors are typically communicated through standard HTTP status codes:
- **404 Not Found**: Returned if the requested prompt or evaluation run cannot be found.
- **401 Unauthorized**: Returned if the user is not authenticated and tries to access the resources.

## Additional Notes

- The controller uses a specific layout, `prompt_engine/admin`, which is designed for administrative interfaces.
- `before_action` hooks are used to set up necessary data (`@prompt` and `@eval_run`) before executing action methods.
- Detailed individual evaluation results are planned for future releases beyond the MVP scope.
