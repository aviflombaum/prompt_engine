---
title: "TestCases API"
layout: "docs"
parent: "api/controllers"
nav_order: "testcases"
---

# TestCasesController API Documentation

## Overview
The `TestCasesController` is part of the `PromptEngine` module in a Rails application. It manages test cases associated with evaluation sets and prompts, providing functionalities like creating, editing, updating, destroying, and importing test cases.

## Authentication
All actions in this controller require the user to be authenticated. Ensure that authentication checks are performed before accessing the actions.

## Actions

### `GET /new`
- **Description:** Renders a form for creating a new test case pre-populated with default values from the associated prompt's parameters.
- **Parameters:** None.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` on success.
- **Example Request:**
  ```bash
  GET /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/new
  ```
- **Example Response:**
  ```html
  <!-- Rendered form for new test case -->
  ```

### `POST /create`
- **Description:** Creates a new test case based on provided input data.
- **Parameters:**
  - `test_case[description]` (optional, string): Description of the test case.
  - `test_case[expected_output]` (required, string): The expected output for the test case.
  - `test_case[input_variables]` (required, hash): Input variables keyed by name.
- **Response Format:** HTML/Redirect
- **Status Codes:**
  - `302 Found` on success (redirect to the eval set path).
  - `200 OK` on form error (re-renders the 'new' template with error messages).
- **Example Request:**
  ```bash
  POST /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases
  Content-Type: application/x-www-form-urlencoded
  Body: test_case[description]=Example&test_case[expected_output]=Result&test_case[input_variables][var1]=value1
  ```
- **Example Response:**
  ```html
  <!-- Redirects or re-renders form with errors -->
  ```

### `GET /edit`
- **Description:** Renders a form for editing an existing test case.
- **Parameters:** None.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` on success.
- **Example Request:**
  ```bash
  GET /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/:id/edit
  ```
- **Example Response:**
  ```html
  <!-- Rendered form for editing test case -->
  ```

### `PUT /update`
- **Description:** Updates an existing test case with provided input data.
- **Parameters:**
  - As in `POST /create`.
- **Response Format:** HTML/Redirect
- **Status Codes:**
  - `302 Found` on success (redirect to the eval set path).
  - `200 OK` on form error (re-renders the 'edit' template with error messages).
- **Example Request:**
  ```bash
  PUT /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/:id
  Content-Type: application/x-www-form-urlencoded
  Body: test_case[description]=Updated Example&test_case[expected_output]=Updated Result&test_case[input_variables][var1]=updatedValue1
  ```
- **Example Response:**
  ```html
  <!-- Redirects or re-renders form with errors -->
  ```

### `DELETE /destroy`
- **Description:** Deletes an existing test case.
- **Parameters:** None.
- **Response Format:** Redirect
- **Status Codes:**
  - `302 Found` on success (redirect to the eval set path).
- **Example Request:**
  ```bash
  DELETE /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/:id
  ```
- **Example Response:**
  ```html
  <!-- Redirects to eval set path with notice -->
  ```

### `GET /import`
- **Description:** Displays a form for importing test cases from a file.
- **Parameters:** None.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` on successful display.
- **Example Request:**
  ```bash
  GET /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/import
  ```
- **Example Response:**
  ```html
  <!-- Rendered form for file import -->
  ```

### `POST /import_preview`
- **Description:** Processes the uploaded file and previews imported test case data.
- **Parameters:**
  - `file` (required, file): A CSV or JSON file containing test case data.
- **Response Format:** HTML
- **Status Codes:**
  - `200 OK` on successful processing and preview.
  - `302 Found` on failure (redirect with error message).
- **Example Request:**
  ```bash
  POST /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/import_preview
  Content-Type: multipart/form-data
  Body: file=@test_cases.csv
  ```
- **Example Response:**
  ```html
  <!-- Renders preview or redirects with error -->
  ```

### `POST /import_create`
- **Description:** Creates test cases from imported data stored in the session.
- **Parameters:** None.
- **Response Format:** Redirect
- **Status Codes:**
  - `302 Found` on success or failure (redirect with success message or error details).
- **Example Request:**
  ```bash
  POST /prompt_engine/prompt/:prompt_id/eval_sets/:eval_set_id/test_cases/import_create
  ```
- **Example Response:**
  ```html
  <!-- Redirects with success message or detailed errors -->
  ```

## Error Handling
Errors are handled by rendering forms with error messages or redirecting with alert messages, depending on the nature of the error. Ensure all forms capture and display errors adequately, and redirects inform the user of any issues encountered during processing.
