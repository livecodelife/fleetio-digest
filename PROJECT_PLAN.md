# Fleet Weekly Digest Pipeline — Ruby Implementation Plan

This document is a **step‑by‑step, opinionated implementation plan** for building a local Ruby pipeline that generates a **"Last Week in My Fleet"** digest using the Fleetio API and a locally running LLM via **LM Studio**.

The goal is to make this pipeline deterministic, repeatable, and easy for an AI coding assistant to implement with minimal ambiguity.

---

## 1. High‑Level Architecture

The pipeline has **four distinct phases**, executed sequentially:

1. **Data Fetching** — Call Fleetio endpoints with date filters
2. **Normalization** — Transform raw API responses into canonical Ruby objects
3. **Composition** — Assemble a single digest payload representing the week
4. **Summarization** — Send composed data to a local LLM and receive a textual digest

Each phase should be isolated in its own namespace and file structure.

---

## 2. Project Structure (Required)

```
/fleet_digest
  /bin
    run_digest.rb

  /lib
    /fleetio
      client.rb
      endpoints.rb

    /normalizers
      vehicle_normalizer.rb
      issue_normalizer.rb
      service_reminder_normalizer.rb

    /digest
      composer.rb
      serializer.rb

    /llm
      client.rb
      prompt_builder.rb

    /utils
      date_range.rb
      logger.rb

  Gemfile
  Gemfile.lock
  README.md
```

This structure is **non‑negotiable** — it enforces separation of concerns and keeps AI‑generated code from mixing responsibilities.

---

## 3. Ruby Version and Dependencies

### Ruby Version

* **Ruby 3.3+** (required)

### Required Gems

Add these to your `Gemfile`:

```ruby
gem 'faraday'
gem 'faraday-retry'
gem 'json'
gem 'dotenv'
gem 'zeitwerk'
gem 'activesupport'
```

**Rationale:**

* `faraday`: HTTP client with middleware support
* `faraday-retry`: automatic retry/backoff
* `dotenv`: local secrets management
* `zeitwerk`: predictable autoloading
* `activesupport`: date/time helpers

---

## 4. Configuration Layer

### Environment Variables

Required environment variables:

```
FLEETIO_API_KEY=...
FLEETIO_ACCOUNT_TOKEN=...
FLEETIO_BASE_URL=https://demo.fleetio.com/api/v1
LM_STUDIO_BASE_URL=http://localhost:1234/v1
LM_STUDIO_MODEL=gemma-3-1b
```

### .env

Load and validate all environment variables on boot. Fail fast if anything is missing.

---

## 5. Fleetio API Client

### lib/fleetio/client.rb

Responsibilities:

* Authentication headers
* Base URL handling
* Retry logic
* JSON parsing

Implementation rules:

* One Faraday connection instance
* No business logic
* No transformations

### Headers (Required)

```http
Authorization: Bearer <API_KEY>
Account-Token: <ACCOUNT_TOKEN>
Accept: application/json
```

---

## 6. Endpoint Access Layer

### lib/fleetio/endpoints.rb

Each endpoint must have its **own method**:

* `fetch_vehicles(start_date:, end_date:)`
* `fetch_issues(start_date:, end_date:)`
* `fetch_service_reminders(start_date:, end_date:)`

Rules:

* Always pass date filters explicitly
* Never hard‑code dates
* Always return parsed JSON hashes

---

## 7. Normalization Layer (Critical)

Raw Fleetio API responses **must never** be passed downstream.

Each resource has a dedicated normalizer responsible for:

* Field selection
* Type coercion
* Key renaming
* Data reduction

### Example: Vehicle Normalizer

`lib/normalizers/vehicle_normalizer.rb`

Input:

```ruby
raw_vehicle # Hash from Fleetio API
```

Output:

```ruby
{
  id: Integer,
  name: String,
  vin: String | nil,
  status: String,
  primary_meter_value: Integer,
  issues_count: Integer,
  service_reminders_count: Integer,
  updated_at: String
}
```

Rules:

* Convert all keys to symbols
* Strip unused fields aggressively
* Never mutate the original hash

Repeat this pattern for Issues and Service Reminders.

---

## 8. Digest Composition

### lib/digest/composer.rb

Responsibilities:

* Accept normalized collections
* Group data by vehicle
* Attach related issues and reminders
* Produce a single digest object

Canonical digest structure:

```ruby
{
  period: {
    start_date: "2026-01-01",
    end_date: "2026-01-07"
  },
  vehicles: [
    {
      vehicle: { ... },
      issues: [ ... ],
      service_reminders: [ ... ]
    }
  ],
  totals: {
    vehicles: Integer,
    issues: Integer,
    overdue_issues: Integer,
    service_reminders: Integer
  }
}
```

This object is the **sole input** to the LLM.

---

## 9. Serialization for LLM Input

### lib/digest/serializer.rb

Responsibilities:

* Convert digest object into readable text
* Maintain deterministic ordering
* Remove noise and duplication

Output format:

* Section headers
* Bullet lists
* Consistent ordering

Example excerpt:

```
Vehicle: Truck A (ID 101)
- Issues:
  - Brake pads worn (overdue)
- Service Reminders:
  - Oil Change due on 2026-01-02
```

This is **intentional** — LLMs summarize text better than raw JSON.

---

## 10. LLM Integration via LM Studio

### lib/llm/client.rb

LM Studio exposes an **OpenAI‑compatible API**.

POST to:

```
http://localhost:1234/v1/chat/completions
```

Request shape:

```json
{
  "model": "gemma-3-1b",
  "messages": [
    { "role": "system", "content": "You are a fleet operations assistant." },
    { "role": "user", "content": "<SERIALIZED DIGEST TEXT>" }
  ],
  "temperature": 0.2
}
```

Rules:

* Low temperature for consistency
* Single user message
* No streaming

---

## 11. Prompt Construction

### lib/llm/prompt_builder.rb

Prompt template:

```
Summarize the following fleet activity from the last week.

Focus on:
- Critical or overdue issues
- Vehicles needing immediate attention
- Overall fleet trends

Do not invent information. Base your summary only on the provided data.

---

<INSERT DIGEST TEXT>
```

---

## 12. Orchestration Script

### bin/run_digest.rb

Execution steps:

1. Load environment
2. Compute last‑week date range
3. Fetch Fleetio data
4. Normalize all resources
5. Compose digest
6. Serialize digest
7. Send prompt to LLM
8. Print summary

This file must contain **no business logic** — only orchestration.

---

## 13. Error Handling Strategy

* Fail fast on missing config
* Retry Fleetio calls (3x max)
* Log all external requests
* Surface LLM failures clearly

---

## 14. Non‑Goals (Explicit)

* No database
* No background jobs
* No web UI
* No external observability
* No concurrency

This is a **single‑run, deterministic pipeline**.

---

## 15. Final Notes for AI Implementation

* Prefer clarity over cleverness
* Write small, pure functions
* Avoid metaprogramming
* Avoid global state
* Keep transformations explicit

If implemented as specified, this pipeline can be regenerated, audited, and evolved safely.
