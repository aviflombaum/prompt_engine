---
title: "Dashboard API"
layout: "docs"
parent: "api/controllers"
nav_order: "dashboard"
---

# DashboardController API Documentation

## Overview
The `DashboardController` within the `PromptEngine` module is designed to provide an overview of various entities and statistics related to the prompt system. It serves as the main interface for summarizing recent activity, overall statistics, and the status of evaluation runs for administrative purposes.

## Authentication Requirements
The usage of this API endpoint typically requires authentication. Ensure that the request is made by an authenticated user with appropriate permissions, usually an admin or a user with a similar role.

## Error Handling
- **401 Unauthorized**: Returned if the user is not authenticated or does not have permission to access the dashboard.
- **500 Internal Server Error**: General catch-all for server errors or unexpected conditions encountered by the server.

## Actions

### 1. Index
- **HTTP Method and Path**: `GET /prompt_engine/dashboard`
- **Description**: Retrieves a summary of recent prompts, test runs, evaluation statistics, and other related metrics.
- **Parameters**: None
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved the dashboard data.
  - `401 Unauthorized`: User is not authenticated or lacks sufficient permissions.
  - `500 Internal Server Error`: An unexpected error occurred.

#### Example Request
```bash
curl -X GET "http://example.com/prompt_engine/dashboard" -H "Authorization: Bearer {access_token}"
```

#### Example Response
```json
{
  "recent_prompts": [
    {
      "id": 1,
      "title": "Sample Prompt 1",
      "updated_at": "2023-12-01T12:00:00Z",
      "parameters": [
        {
          "id": 101,
          "name": "Parameter1"
        }
      ]
    }
  ],
  "recent_test_runs": [
    {
      "id": 201,
      "result": "success",
      "created_at": "2023-12-02T15:30:00Z",
      "prompt_version": {
        "id": 301,
        "prompt": {
          "id": 1,
          "title": "Sample Prompt 1"
        }
      }
    }
  ],
  "statistics": {
    "total_prompts": 150,
    "prompt_engines": 120,
    "total_test_runs": 450,
    "total_tokens_used": 97000
  },
  "evaluation_statistics": {
    "total_eval_sets": 5,
    "total_eval_runs": 20,
    "recent_eval_runs": [
      {
        "id": 401,
        "status": "completed",
        "created_at": "2023-12-03T11:20:00Z",
        "eval_set": {
          "id": 501,
          "prompt": {
            "id": 1,
            "title": "Sample Prompt 1"
          }
        }
      }
    ]
  }
}
```

This endpoint provides a comprehensive view of the most recent and relevant data concerning the prompt system's operations, making it an essential tool for system monitoring and management.
