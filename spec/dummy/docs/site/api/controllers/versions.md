---
title: "Versions API"
layout: "docs"
parent: "api/controllers"
nav_order: "versions"
---

# PromptEngine::VersionsController API Documentation

## Overview

The `VersionsController` manages different versions of prompts within the `PromptEngine` module. It allows operations such as viewing, comparing, and restoring versions of prompts.

### Authentication

This API requires user authentication. Ensure the user is authenticated before attempting to access these endpoints.

### Error Handling

Errors are handled by returning appropriate HTTP status codes along with error messages describing the issue.

## API Endpoints

### 1. List Versions

- **HTTP Method and Path**: `GET /prompts/:prompt_id/versions`
- **Description**: Retrieves a list of all versions associated with a specific prompt.
- **Parameters**:
  - `prompt_id` (required): The ID of the prompt.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved list.
  - `401 Unauthorized`: User not authenticated.
- **Example Request**:
  ```http
  GET /prompts/123/versions
  ```
- **Example Response**:
  ```json
  [
    {
      "id": 1,
      "content": "Example content v1",
      "version_number": 1
    },
    {
      "id": 2,
      "content": "Example content v2",
      "version_number": 2
    }
  ]
  ```

### 2. Show Version Details

- **HTTP Method and Path**: `GET /prompts/:prompt_id/versions/:id`
- **Description**: Displays details of a specific version of a prompt.
- **Parameters**:
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The version ID.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully retrieved version details.
  - `401 Unauthorized`: User not authenticated.
  - `404 Not Found`: The specified version does not exist.
- **Example Request**:
  ```http
  GET /prompts/123/versions/1
  ```
- **Example Response**:
  ```json
  {
    "id": 1,
    "content": "Example content v1",
    "version_number": 1
  }
  ```

### 3. Compare Versions

- **HTTP Method and Path**: `GET /prompts/:prompt_id/versions/compare`
- **Description**: Compares two different versions of a prompt and shows changes.
- **Parameters**:
  - `prompt_id` (required): The ID of the prompt.
  - `version_a_id` (optional): The ID of the first version.
  - `version_b_id` (optional): The ID of the second version.
- **Response Format**: JSON
- **Status Codes**:
  - `200 OK`: Successfully compared versions.
  - `302 Found`: Redirects if necessary parameters are missing.
  - `401 Unauthorized`: User not authenticated.
- **Example Request**:
  ```http
  GET /prompts/123/versions/compare?version_a_id=1&version_b_id=2
  ```
- **Example Response**:
  ```json
  {
    "content": { "old": "Example content v1", "new": "Example content v2", "changed": true },
    "system_message": { "old": "System message v1", "new": "System message v2", "changed": true },
    "model": { "old": "Model v1", "new": "Model v2", "changed": true }
  }
  ```

### 4. Restore Version

- **HTTP Method and Path**: `POST /prompts/:prompt_id/versions/:id/restore`
- **Description**: Restores the prompt to the selected version.
- **Parameters**:
  - `prompt_id` (required): The ID of the prompt.
  - `id` (required): The version ID to restore.
- **Response Format**: Redirect
- **Status Codes**:
  - `302 Found`: Successfully restored and redirected.
  - `401 Unauthorized`: User not authenticated.
  - `404 Not Found`: The specified version does not exist.
- **Example Request**:
  ```http
  POST /prompts/123/versions/1/restore
  ```
- **Example Response**:
  ```http
  HTTP/1.1 302 Found
  Location: /prompts/123
  ```

This documentation provides a comprehensive guide on how to interact with the `VersionsController` endpoints, including necessary parameters, expected responses, and handling of potential errors.
