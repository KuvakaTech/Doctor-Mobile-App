# Kiosk Session Timeline Analysis (Detailed)

This document outlines the detailed chronological sequence of API requests captured from the `medical-history.kuvaka.io.har` file. It maps out a complete user journey: from an administrator logging in, to setting up a physical ticketing kiosk, and a patient completing a full AI voice consultation.

All backend requests are made to `med-history-agent.decrackle.io`.

---

## The Timeline

### 1. 10:21:15 AM — Administrator Login
*   **Method:** `POST`
*   **Endpoint:** `/api/v1/auth/login`
*   **Headers:** `content-type: application/json`
*   **Request Body:**
    ```json
    {
      "email": "admin.jawar@example.com",
      "password": "LocalAdmin#2026"
    }
    ```
*   **Action:** The user successfully authenticates using their credentials and receives a JWT (JSON Web Token). This token contains embedded payload data, including the user's role and their assigned `hospital_id`.

### 2. 10:21:19 AM — Fetching Hospital Details
*   **Method:** `GET`
*   **Endpoint:** `/api/v2/admin/hospital?hospital_id=ccff0c21-5b2a-4103-b2c3-0ac79ba807fb`
*   **Action:** The frontend decodes the JWT, extracts the `hospital_id`, and fetches the details for this specific hospital. The response indicates the hospital slug is `jawar`. The web application then redirects the browser to the dedicated check-in page for this hospital (`/checkin/jawar`).
*   **Response:**
    ```json
    {
        "hospital_id": "<uuid-string>",
        "slug": "<string>",
        "name": "<string>",
        "default_language": "<string, e.g. 'en' | 'hi'>",
        "collect_caste": "<boolean>",
        "created_at": "<ISO 8601 datetime string>",
        "has_kiosk_pin": "<boolean>"
    }
    ```

### 3. 10:21:21 AM — Loading Kiosk Settings
*   **Method:** `GET`
*   **Endpoint:** `/api/v2/t/jawar/config`
*   **Action:** The ticketing kiosk interface loads and fetches its required configuration. This dictates UI behavior, such as whether a PIN is required to unlock it and if specific demographic data (like caste) should be collected.
*   **Response:**
    ```json
    {
        "slug": "<string>",
        "name": "<string>",
        "collect_caste": "<boolean>",
        "has_kiosk_pin": "<boolean>"
    }
    ```

### 4. 10:22:13 AM — Unlocking the Physical Kiosk
*   **Method:** `POST`
*   **Endpoint:** `/api/v2/t/jawar/unlock`
*   **Headers:** `content-type: application/json`
*   **Request Body:**
    ```json
    {
      "pin": "582940"
    }
    ```
*   **Action:** Approximately a minute later, the operator types in the physical 6-digit PIN code on the device to unlock it for public use. The backend validates the PIN and returns a short-lived, kiosk-specific access token.
*   **Response:**
    ```json
    {
        "access_token": "<JWT string>",
        "token_type": "<string, e.g. 'bearer'>",
        "expires_in": "<integer, seconds>",
        "hospital_name": "<string>",
        "collect_caste": "<boolean>"
    }
    ```

### 5. 10:22:36 AM — Starting a Patient Session
*   **Method:** `POST`
*   **Endpoint:** `/api/v2/t/jawar/session`
*   **Headers:** `content-type: application/json`
*   **Request Body:**
    ```json
    {
      "phone": "0000000000",
      "language": "hi",
      "visit_type": "ipd",
      "gender": "female"
    }
    ```
*   **Action:** A patient approaches the kiosk, enters their basic details (e.g., phone number, preferred language (Hindi `hi`), gender, and visit type), and starts a consultation. The backend registers this new session and generates a unique session ID (`dad68b28-0c69-4da1-946d-1b5ce926e600`).
*   **Response:**
    ```json
    {
        "session_id": "<uuid-string>",
        "ticket_number": "<string>",
        "opd_number": "<integer>",
        "patient_id": "<uuid-string>",
        "language": "<string, ISO 639-1 code>",
        "phase": "<string, enum>",
        "status": "<string, enum>"
    }
    ```

### 6. 10:22:38 AM — Active Voice Consultation
*   **Method:** `WebSocket (GET)`
*   **Endpoint:** `wss://med-history-agent.decrackle.io/api/v2/t/jawar/session/dad68b28-0c69-4da1-946d-1b5ce926e600/voice?token=eyJhbGciOiJIUzI...`
*   **Action:** Almost immediately after the session is created, the browser establishes a bi-directional WebSocket connection. The authorization token is passed securely in the URL query parameters. The kiosk streams 16kHz PCM audio from the microphone to the server, and the server streams 24kHz PCM audio back from the AI agent. 
*   **Duration:** The patient converses with the AI for approximately **2.5 minutes**.
*   **Response Events:** For a complete catalog of real-time WebSocket events (such as `triage_started`, `agent_speaking`, `partial_transcript`, `category_identified`, and `result_ready`), please refer to the specific documentation found in [`websocket-message-catalog.md`](file:///E:/Code/med-history-agent/websocket-message-catalog.md).

### 7. 10:25:10 AM — Retrieving Final Results
*   **Method:** `GET`
*   **Endpoint:** `/api/v2/t/jawar/session/dad68b28-0c69-4da1-946d-1b5ce926e600/result`
*   **Action:** The voice consultation naturally concludes, and the WebSocket is closed. The kiosk automatically fetches the final generated ticket/summary of the consultation, which is then displayed on the screen and presumably printed for the patient.
*   **Response:**
    ```json
    {
        "session_id": "<uuid-string>",
        "ticket_number": "<string>",
        "opd_number": "<integer>",
        "opd_date_ist": "<date string, YYYY-MM-DD>",
        "visit_type": "<string, enum e.g. 'ipd' | 'opd'>",
        "collect_caste": "<boolean>",
        "phase": "<string, enum e.g. 'triage' | 'consultation' | 'result'>",
        "status": "<string, enum e.g. 'active' | 'completed'>",
        "category": {
            "key": "<string, machine-readable category id>",
            "label": "<string, human-readable category name>",
            "source": "<string, enum e.g. 'auto' | 'manual'>"
        },
        "flags": [
            {
                "flag_type": "<string, enum 'NOTE' | 'IMPORTANT'>",
                "description": "<string>",
                "raised_at": "<ISO 8601 datetime string>"
            }
        ],
        "summary": "<string | null>",
        "started_at": "<string, 'YYYY-MM-DD HH:MM:SS TZ'>",
        "ended_at": "<string, 'YYYY-MM-DD HH:MM:SS TZ'>",
        "patient": {
            "patient_id": "<uuid-string>",
            "name": "<string>",
            "age": "<integer>",
            "gender": "<string, enum e.g. 'male' | 'female' | 'other'>",
            "caste": "<string>",
            "address": "<string>",
            "guardian_name": "<string>",
            "phone": "<string>"
        },
        "hospital_name": "<string>"
    }
    ```

### 8. 10:25:33 AM — Kiosk Reset
*   **Method:** `GET`
*   **Endpoint:** `/api/v2/t/jawar/config`
*   **Action:** The patient completes their flow, and the kiosk UI resets back to the initial idle screen, fetching the config once again to be ready to greet and check in the next patient.
