# Swift Generic Sync Engine

This command-line project models a local cache synchronized with a fixture-backed remote source. Protocol associated types and a same-type `where` constraint ensure that both sides use the same entity model.

## Requirements

- macOS 13 or later
- Swift 5.9 or later (`swift --version`)

## Run

```bash
git clone https://github.com/2252408699/swift-generic-sync-engine.git
cd swift-generic-sync-engine
swift run
```

The executable performs seven checks and ends with `All generic sync checks passed.`

