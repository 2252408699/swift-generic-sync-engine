import Foundation

protocol Entity: Codable, Equatable {
    associatedtype ID: Hashable
    var id: ID { get }
}

protocol Repository {
    associatedtype Model: Entity
    func all() -> [Model]
    func save(_ models: [Model])
}

protocol RemoteSource {
    associatedtype Model: Entity
    func fetch() throws -> [Model]
}

final class InMemoryRepository<Model: Entity>: Repository {
    private var storage: [Model.ID: Model]

    init(seed: [Model] = []) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    func all() -> [Model] {
        Array(storage.values)
    }

    func save(_ models: [Model]) {
        for model in models {
            storage[model.id] = model
        }
    }
}

struct FixtureRemote<Model: Entity>: RemoteSource {
    let models: [Model]

    func fetch() throws -> [Model] {
        models
    }
}

struct SyncReport<ID: Hashable> {
    let inserted: [ID]
    let updated: [ID]
    let unchanged: [ID]
}

struct SyncEngine<Local: Repository, Remote: RemoteSource>
where Local.Model == Remote.Model {
    let local: Local
    let remote: Remote

    func sync() throws -> SyncReport<Local.Model.ID> {
        let existing = Dictionary(
            uniqueKeysWithValues: local.all().map { ($0.id, $0) }
        )
        let incoming = try remote.fetch()

        var inserted: [Local.Model.ID] = []
        var updated: [Local.Model.ID] = []
        var unchanged: [Local.Model.ID] = []

        for model in incoming {
            guard let oldModel = existing[model.id] else {
                inserted.append(model.id)
                continue
            }
            if oldModel == model {
                unchanged.append(model.id)
            } else {
                updated.append(model.id)
            }
        }

        local.save(incoming)
        return SyncReport(inserted: inserted, updated: updated, unchanged: unchanged)
    }
}

struct TaskRecord: Entity {
    let id: String
    let title: String
    let isDone: Bool
}

func makeTaskRepository(seed: [TaskRecord]) -> some Repository {
    InMemoryRepository(seed: seed)
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    print("PASS: \(message)")
}

let local = InMemoryRepository(seed: [
    TaskRecord(id: "T-1", title: "Write draft", isDone: false),
    TaskRecord(id: "T-3", title: "Keep unchanged", isDone: true)
])

let remote = FixtureRemote(models: [
    TaskRecord(id: "T-1", title: "Write final draft", isDone: true),
    TaskRecord(id: "T-2", title: "Run tests", isDone: false),
    TaskRecord(id: "T-3", title: "Keep unchanged", isDone: true)
])

let engine = SyncEngine(local: local, remote: remote)
let report = try engine.sync()
let recordsByID = Dictionary(uniqueKeysWithValues: local.all().map { ($0.id, $0) })

check(report.inserted == ["T-2"], "sync reports the inserted task")
check(report.updated == ["T-1"], "sync reports the updated task")
check(report.unchanged == ["T-3"], "sync reports the unchanged task")
check(local.all().count == 3, "local repository contains three tasks")
check(recordsByID["T-1"]?.isDone == true, "updated value replaces cached value")
check(recordsByID["T-2"]?.title == "Run tests", "new remote value is cached")

let opaqueRepository = makeTaskRepository(seed: [])
check(opaqueRepository.all().isEmpty, "opaque repository preserves its hidden concrete type")

print("All generic sync checks passed.")
