import Foundation

@MainActor
final class MessageStore: ObservableObject {
    @Published private(set) var messages: [SMSMessage] = []

    private let fileURL: URL
    private let backupURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager
    private var deletedMessages: DeletedMessageRegistry

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = AppDataDirectory.userApplicationSupport(fileManager: fileManager)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            PersistenceErrorReporter.report(context: "无法准备短信存储目录", error: error)
        }
        fileURL = directory.appendingPathComponent("messages.json")
        backupURL = directory.appendingPathComponent("messages.backup.json")
        deletedMessages = DeletedMessageRegistry(
            fileURL: directory.appendingPathComponent("deleted-message-ids.json")
        )

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var unreadCount: Int {
        messages.lazy.filter { !$0.isRead }.count
    }

    @discardableResult
    func merge(_ incoming: [SMSMessage]) -> [SMSMessage] {
        let visibleIncoming = incoming.filter { !deletedMessages.contains($0.id) }
        let result = SMSMessageMerger.merge(existing: messages, incoming: visibleIncoming)
        let updated = result.messages
        if updated != messages {
            messages = updated
            save(context: "无法保存短信")
        }
        return result.newlyDiscovered
    }

    func markRead(id: SMSMessage.ID, at date: Date = Date()) {
        markRead(ids: [id], at: date)
    }

    func markRead(ids: Set<SMSMessage.ID>, at date: Date = Date()) {
        guard !ids.isEmpty else { return }
        var changed = false
        for index in messages.indices where ids.contains(messages[index].id) {
            if !messages[index].isRead {
                messages[index].isRead = true
                changed = true
            }
            if messages[index].readAt == nil {
                messages[index].readAt = date
                changed = true
            }
        }
        if changed { save(context: "无法保存短信已读状态") }
    }

    @discardableResult
    func appendOutgoing(
        to destination: String,
        body: String,
        moduleID: CellularModuleID? = nil,
        at date: Date = Date()
    ) -> SMSMessage.ID {
        let message = SMSMessage(
            id: "outgoing-\(UUID().uuidString)",
            moduleID: moduleID,
            modemIndices: [],
            sender: destination,
            body: body,
            timestamp: date,
            rawPDUs: [],
            isRead: true,
            readAt: date,
            firstSeenAt: date,
            direction: .outgoing,
            deliveryState: .sending
        )
        messages.insert(message, at: 0)
        save(context: "无法保存已发送短信")
        return message.id
    }

    func updateOutgoing(
        id: SMSMessage.ID,
        state: SMSDeliveryState,
        detail: String? = nil
    ) {
        guard let index = messages.firstIndex(where: { $0.id == id }),
              messages[index].isOutgoing else { return }
        messages[index].deliveryState = state
        messages[index].deliveryDetail = detail
        save(context: "无法保存短信发送状态")
    }

    func markAllRead(at date: Date = Date()) {
        var changed = false
        for index in messages.indices {
            if !messages[index].isRead {
                messages[index].isRead = true
                changed = true
            }
            if messages[index].readAt == nil {
                messages[index].readAt = date
                changed = true
            }
        }
        if changed { save(context: "无法保存短信已读状态") }
    }

    func resetVerificationReadDates(at date: Date = Date()) {
        var changed = false
        for index in messages.indices where
            messages[index].isRead && messages[index].verificationCode != nil {
            if messages[index].readAt != date {
                messages[index].readAt = date
                changed = true
            }
        }
        if changed { save(context: "无法保存短信已读状态") }
    }

    func fillMissingVerificationReadDates(at date: Date = Date()) {
        var changed = false
        for index in messages.indices where
            messages[index].isRead &&
                messages[index].verificationCode != nil &&
                messages[index].readAt == nil {
            messages[index].readAt = date
            changed = true
        }
        if changed { save(context: "无法保存短信已读状态") }
    }

    func remove(id: SMSMessage.ID, at date: Date = Date()) {
        do {
            try deletedMessages.insert(id, at: date)
        } catch {
            PersistenceErrorReporter.report(context: "无法保存短信删除记录", error: error)
            return
        }
        let originalCount = messages.count
        messages.removeAll { $0.id == id }
        if messages.count != originalCount { save(context: "无法保存短信删除结果") }
    }

    func invalidateModemReferences() {
        var changed = false
        for index in messages.indices where
            !messages[index].effectiveModemReferences.isEmpty ||
                !messages[index].modemIndices.isEmpty ||
                messages[index].modemStorage != nil {
            messages[index].clearModemReferences()
            changed = true
        }
        if changed { save(context: "无法保存短信状态") }
    }

    func invalidateModemReferences(for moduleID: CellularModuleID) {
        var changed = false
        for index in messages.indices where
            messages[index].moduleID == moduleID &&
                (!messages[index].effectiveModemReferences.isEmpty ||
                    !messages[index].modemIndices.isEmpty ||
                    messages[index].modemStorage != nil) {
            messages[index].clearModemReferences()
            changed = true
        }
        if changed { save(context: "无法保存短信状态") }
    }

    private func load() {
        let decoded = decodeMessages(at: fileURL) ?? decodeMessages(at: backupURL)
        guard let decoded else {
            messages = []
            return
        }
        messages = decoded.filter { !deletedMessages.contains($0.id) }.map { message in
            var detached = message
            detached.clearModemReferences()
            if detached.deliveryState == .sending {
                detached.deliveryState = .uncertain
                detached.deliveryDetail = SMSMessage.interruptedDeliveryDetailCode
            }
            return detached
        }.sorted { $0.timestamp > $1.timestamp }
    }

    private func save(context: String) {
        do {
            let data = try encoder.encode(messages)
            if fileManager.fileExists(atPath: fileURL.path),
               decodeMessages(at: fileURL, reportErrors: false) != nil {
                let existingData = try Data(contentsOf: fileURL)
                try existingData.write(to: backupURL, options: .atomic)
            }
            try data.write(to: fileURL, options: .atomic)
        } catch {
            PersistenceErrorReporter.report(context: context, error: error)
        }
    }

    private func decodeMessages(at url: URL, reportErrors: Bool = true) -> [SMSMessage]? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([SMSMessage].self, from: data)
        } catch {
            if reportErrors {
                PersistenceErrorReporter.report(context: "无法读取短信记录", error: error)
            }
            return nil
        }
    }

}
