# Flutter Implementation Guide: Kiosk Ticketing Flow

This document provides a technical blueprint for implementing the **Kiosk Ticketing Flow** in the existing Flutter/Dart application. 

This guide is based on the API behavior observed in the Next.js web frontend.

---

## 1. Authentication Strategy

> [!IMPORTANT]
> **Use the Existing Infrastructure:** 
> The Flutter app already has a comprehensive authentication system and token management setup for other types of consultations. **Do not rebuild login or token storage logic.** 
> 
> You should rely on the existing Dart services (e.g., `AuthService`, `TokenManager`, or `ApiClient`) to:
> - Handle the initial user/admin login.
> - Inject the Bearer token into HTTP headers.
> - Decode the JWT payload to extract the current user's `role` and `hospital_id`.

---

## 2. API Flow Implementation

Create a new service (e.g., `KioskTicketingService`) to handle the following sequential API calls. Use the existing HTTP client setup to ensure standard error handling and token injection.

### Step 1: Flow Selection (UI Routing)
Before initiating any Kiosk-specific API calls, the user must navigate through the new UX flow:
1.  **User Logs In:** The user authenticates via the existing login screen.
2.  **Flow Selection Screen:** Post-login, route the user to the `FlowSelectionScreen` instead of a default dashboard.
3.  **Initiate Kiosk Flow:** When the user selects the "Kiosk Ticketing" (or similar) option from this screen, trigger the sequence below to initialize the kiosk.

### Step 2: Fetch Hospital & Kiosk Config
Once the Kiosk flow is selected, use the existing token to determine the user's scope and fetch the kiosk settings.

1.  **Extract `hospital_id`**: Decode the JWT (using your existing token utilities or manually via `jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))))`).
2.  **Get Hospital Slug**: 
    - `GET /api/v2/admin/hospital?hospital_id={extracted_id}`
    - Save the returned `slug` (e.g., `jawar`).
3.  **Get Kiosk Config**:
    - `GET /api/v2/t/{slug}/config`
    - Returns UI settings like `collect_caste` and `has_kiosk_pin`.

### Step 3: Kiosk Unlock
The physical kiosk UI needs to be unlocked by an operator before patients can use it.

-   **Endpoint:** `POST /api/v2/t/{slug}/unlock`
-   **Body:** `{"pin": "123456"}`
-   **Response:** Returns a short-lived `access_token` scoped *only* to this kiosk.
-   **Action:** Save this specific Kiosk Token in memory. All subsequent patient requests (Steps 3-5) must use this specific token instead of the main Admin token.

### Step 4: Start Patient Session
When a patient approaches, collect their details via a Flutter form.

-   **Endpoint:** `POST /api/v2/t/{slug}/session`
-   **Body:** 
    ```json
    {
      "phone": "9999999999",
      "language": "hi",
      "visit_type": "ipd",
      "gender": "female"
    }
    ```
-   **Response:** Returns the `session_id` required for the voice call.

### Step 5: Real-time Voice Consultation (WebSocket)
This is the core of the consultation. You will need to establish a WebSocket connection to stream audio.

-   **Endpoint:** `wss://med-history-agent.decrackle.io/api/v2/t/{slug}/session/{session_id}/voice?token={kiosk_token}`
-   **Dart Implementation:** 
    - Use the [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) package.
    - **Microphone Capture:** Use a package like [`record`](https://pub.dev/packages/record) to capture audio from the device mic. You must configure it to capture at **16kHz, Mono, PCM 16-bit** to match the server's expectations. Stream these raw bytes directly over the WebSocket.
    - **Audio Playback:** The server will send JSON messages (e.g., `{"type": "agent_audio_chunk", "audio_b64": "..."}`). Decode the Base64 string into a `Uint8List` (PCM 24kHz) and play it back using an audio package capable of playing raw PCM streams (like [`soundpool`](https://pub.dev/packages/soundpool) or a custom native channel).
    - **Events:** Parse the incoming JSON messages according to the existing `websocket-message-catalog.md` (handling `triage_started`, `agent_speaking`, `result_ready`, etc.) to update the Flutter UI.

### Step 6: Fetch Final Results
Once the WebSocket sends the `ended` or `result_ready` event, close the connection and fetch the final ticket.

-   **Endpoint:** `GET /api/v2/t/{slug}/session/{session_id}/result`
-   **Action:** Display the ticket details, summary, and flags on the Flutter screen. Once the user dismisses the screen, route back to the Kiosk Unlock or Start Session screen.

---

## 3. Data Models

You will need to create Dart models (`freezed` or standard classes with `json_serializable`) for the JSON responses documented previously. 

**Required Models:**
- `HospitalDetails` (for `/hospital`)
- `KioskConfig` (for `/config`)
- `KioskUnlockResult` (for `/unlock`)
- `PatientSessionInit` (for `/session`)
- `TicketingResult` (for `/result`)
- `WebSocketEvent` (A sealed class/union type representing the different incoming WS messages).
