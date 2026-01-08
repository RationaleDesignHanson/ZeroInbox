# Watch Core Bridge (v2.0)

This short note links the existing watch targets to the new shared TypeScript core packages:

1) Classifications should be pre-computed on iPhone using `@zero/intent-engine`, `@zero/action-resolver`, and `@zero/confidence` and sent over `WatchConnectivity` with the email payload.
2) When iPhone is unavailable, the watch can fallback to a tiny JS bundle built from `@zero/core` for local classification; use the same `EmailContext` shape defined in `@zero/core-types`.
3) Telemetry events from the watch should reuse `@zero/telemetry` schemas: `action_modal_shown`, `action_taken`, `action_undone`. Queue locally and flush on reconnect.
4) Undo / offline queue: keep last 50 emails + pending actions in the existing local cache, tagging each with the resolved `ActionType` and confidence bucket from the shared core.
5) Kill switch: if the shared core bundle is missing or stale, present the default action menu and log a telemetry event with `confidenceBucket=uncertain`.

Next steps for implementation:
- Add a lightweight JS bundle for watch from `packages/core` during the mobile build.
- Extend `WatchConnectivityManager` to pass `intent`, `confidence`, and `suggestedAction` fields.
- Emit telemetry via the same endpoint as mobile using the `@zero/telemetry` schema.


