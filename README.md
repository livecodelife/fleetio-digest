# Fleet Weekly Digest Pipeline

A local Ruby pipeline that generates a **"Last Week in My Fleet"** digest using the Fleetio API and a locally running LLM via **LM Studio**.

## 🚀 Overview

This system automates the process of gathering weekly fleet activity from Fleetio and summarizing it into a concise, readable report using AI. It is designed to be deterministic, repeatable, and easy to run locally.

---

## 🏗 Architecture

The pipeline follows a distinct four-phase sequential execution model:

### 1. Data Fetching
*   **Location:** `lib/fleetio/`
*   **Responsibility:** Communicates with the Fleetio API.
*   **Key Files:** `client.rb` (Auth, retries, JSON parsing) and `endpoints.rb` (Specific resource fetching for Vehicles, Issues, and Service Reminders).

### 2. Normalization
*   **Location:** `lib/normalizers/`
*   **Responsibility:** Transforms raw API responses into canonical Ruby objects.
*   **Strategy:** Aggressive data reduction, field renaming, and type coercion. This ensures that downstream components are decoupled from the specific structure of the Fleetio API.

### 3. Composition
*   **Location:** `lib/digest/`
*   **Responsibility:** Assembles a structured "Digest" object.
*   **Strategy:** Groups issues and service reminders by vehicle, calculates totals, and defines the report period.

### 4. Summarization
*   **Location:** `lib/llm/`
*   **Responsibility:** interfaces with a local LLM via LM Studio.
*   **Process:**
    1.  **Serialization:** The digest object is converted into a human-readable text format (see `lib/digest/serializer.rb`).
    2.  **Prompt Building:** A structured prompt is constructed to guide the LLM.
    3.  **Completion:** The prompt is sent to an OpenAI-compatible endpoint.

---

## 🎨 Design Commentary

### Separation of Concerns
The project structure enforces a strict boundary between fetching data, cleaning it, and processing it. This makes the code highly modular and simplifies testing or swapping out components (e.g., swapping Fleetio for another provider or changing the LLM).

### Local‑First LLM
By utilizing **LM Studio**, the pipeline maintains data privacy and avoids external API costs. The system expects an OpenAI-compatible API, making it compatible with many local LLM runners.

### Determinism and Reliability
*   **Retries:** The Fleetio client includes automatic retries for flaky network connections.
*   **Fail Fast:** The system validates environment variables on boot and crashes immediately if any are missing.
*   **Text over JSON:** We serialize the digest into structured text before sending it to the LLM. Experience shows that LLMs summarize structured text more reliably than raw, deeply nested JSON objects.

---

## 🛠 Setup & Run

### Prerequisites
*   **Ruby 3.3+**
*   **LM Studio** (running with an OpenAI-compatible server on port 1234)
*   **Fleetio API Credentials**

### 1. Installation
Clone the repository and install dependencies:
```bash
bundle install
```

### 2. Configuration
Copy the example environment file and fill in your credentials:
```bash
cp .env.example .env
```
Edit `.env` with your `FLEETIO_API_KEY`, `FLEETIO_ACCOUNT_TOKEN`, etc.

### 3. Running the Pipeline
Simply execute the orchestration script:
```bash
ruby bin/run_digest.rb
```

You can optionally override the model or base URL:
```bash
ruby bin/run_digest.rb <model_name> <base_url>
```

---

## 📂 Project Structure

*   `bin/`: CLI entry point (`run_digest.rb`).
*   `lib/fleetio/`: API communication layer.
*   `lib/normalizers/`: Data transformation logic.
*   `lib/digest/`: Data composition and serialization.
*   `lib/llm/`: LLM client and prompt construction.
*   `fixtures/`: API response examples for development and testing.
