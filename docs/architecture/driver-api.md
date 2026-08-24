# Ring driver API

`ring_ble` defines the protocol-independent `RingDriver` and `RingBleTransport`
interfaces. A driver owns advertisement matching, connection, capability
discovery, sync, live sessions, settings, and disconnection. The transport owns
platform scan/connect/discovery/subscribe/write operations.

Drivers return `ring_core` records. UI code never sees UUIDs or raw byte arrays,
and protocol code never imports Flutter. Undeclared capabilities are unavailable
by default; the UI must not infer support from a model name.

The current `ColmiQringDriver` validates services and reports corroborated
capability candidates, but throws `ProtocolEvidenceIncompleteException` before
unverified sync, live, or setting commands can reach the transport.
