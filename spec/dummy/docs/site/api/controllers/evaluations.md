---
title: "Evaluations API"
layout: "docs"
parent: "api/controllers"
nav_order: "evaluations"
---

# EvaluationsController API Documentation

## Overview

The `EvaluationsController` within the `PromptEngine` module manages the retrieval and presentation of evaluation data related to prompts in a system designed for prompt management and analysis. It aggregates and displays statistics on evaluation sets, evaluation runs, and test cases, including recent activity and overall pass rates.

---

## Actions

### GET /prompt_engine/evaluations

Retrieves and displays a summary of evaluation data, recent activity, and statistical analysis regarding the evaluation sets and runs.

#### Description

This endpoint provides a comprehensive dashboard view of the evaluations, featuring lists of prompts with their associated evaluation sets, counts of total evaluation sets, runs, and test cases, as well as recent evaluation activity and overall pass rates for completed evaluations.

#### Parameters

- **None**

#### Response Format

- **Content-Type**: `text/html`
- The response is rendered as HTML using the "prompt_engine/admin" layout, which organizes the fetched data into a readable format suitable for an admin dashboard.

#### Status Codes

- **200 OK**: Successfully retrieved and rendered the evaluation data.
- **401 Unauthorized**: User is not authenticated and cannot access this resource.
- **500 Internal Server Error**: Unexpected error occurred in processing the request.

#### Example Request

```bash
GET /prompt_engine/evaluations HTTP/1.1
Host: example.com
Authorization: Bearer YOUR_ACCESS_TOKEN
```

#### Example Response

```html
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
    <title>Evaluation Summary</title>
</head>
<body>
    <h1>Evaluation Dashboard</h1>
    <div>Total Evaluation Sets: 42</div>
    <div>Total Evaluation Runs: 128</div>
    <div>Total Test Cases: 512</div>
    <div>Overall Pass Rate: 75.00%</div>
    <!-- Further HTML content displaying the data in tables or charts -->
</body>
</html>
```

---

## Authentication

- This controller action requires user authentication. Users must be logged in to access the evaluation data. Ensure the request includes a valid authentication token.

---

## Error Handling

- **401 Unauthorized**: Returned if the user tries to access the endpoint without being authenticated. Ensure the user is properly logged in and the correct token is included in the request headers.
- **500 Internal Server Error**: This is a generic error message when an unexpected condition was encountered in the server. It could be due to database issues, backend services failure, or an unhandled exception in the code. Check server logs for more detailed diagnostics.

---

For further details or support, please contact the API team or refer to the internal developer documentation specific to the `PromptEngine` system.
