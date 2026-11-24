import Foundation

enum PrivacyProtectionPreferences {
    static let enabledKey = "PresentationPrivacyProtectionEnabled.v1"
    static let aliasSaltKey = "PresentationPrivacyAliasSalt.v1"

    static func aliasSalt(defaults: UserDefaults = .standard) -> String {
        if let existing = defaults.string(forKey: aliasSaltKey), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: aliasSaltKey)
        return generated
    }
}

struct PrivacyPresentation: Equatable {
    let isEnabled: Bool
    let aliasSalt: String

    func identity(
        contactName: String?,
        number: String?,
        identifier: String? = nil,
        fallback: String? = nil
    ) -> String {
        let name = nonempty(contactName)
        let rawNumber = nonempty(number)
        let resolvedFallback = fallback ?? L10n.tr("未知号码")
        guard isEnabled else {
            return name ?? rawNumber ?? resolvedFallback
        }

        let aliasSource = identifier ?? rawNumber ?? name ?? resolvedFallback
        let code = aliasCode(for: aliasSource)
        return name == nil
            ? L10n.tr("号码 %@", code)
            : L10n.tr("联系人 %@", code)
    }

    func contactIdentity(
        name: String,
        identifier: String,
        fallbackNumber: String? = nil
    ) -> String {
        identity(
            contactName: name,
            number: fallbackNumber,
            identifier: identifier,
            fallback: L10n.tr("未命名联系人")
        )
    }

    func phoneNumber(_ value: String?, fallback: String? = nil) -> String {
        let resolvedFallback = fallback ?? L10n.tr("未知号码")
        guard let value = nonempty(value) else { return resolvedFallback }
        return isEnabled ? L10n.tr("号码已隐藏") : value
    }

    func messageText(_ value: String, emptyFallback: String? = nil) -> String {
        let resolvedFallback = emptyFallback ?? L10n.tr("（空短信）")
        if isEnabled {
            return value.isEmpty ? resolvedFallback : L10n.tr("短信内容已隐藏")
        }
        return value.isEmpty ? resolvedFallback : value
    }

    func messagePreview(_ value: String) -> String {
        isEnabled && !value.isEmpty ? L10n.tr("短信内容已隐藏") : value
    }

    func verificationCode(_ value: String) -> String {
        isEnabled ? L10n.tr("验证码已隐藏") : L10n.tr("验证码 %@", value)
    }

    func recordingTitle(
        customTitle: String?,
        contactName: String?,
        number: String
    ) -> String {
        guard isEnabled else {
            return nonempty(customTitle) ?? nonempty(contactName) ?? number
        }
        return L10n.tr("通话录音 %@", aliasCode(for: number))
    }

    func privateDetail(_ value: String?, fallback: String? = nil) -> String {
        let resolvedFallback = fallback ?? L10n.tr("尚未填写")
        guard let value = nonempty(value) else { return resolvedFallback }
        return isEnabled ? L10n.tr("信息已隐藏") : value
    }

    func groupName(_ value: String, identifier: String) -> String {
        isEnabled ? L10n.tr("分组 %@", aliasCode(for: identifier)) : value
    }

    func simPhoneNumber(_ value: String?) -> String {
        guard let value = nonempty(value) else { return L10n.tr("SIM 未提供本机号码") }
        return isEnabled ? L10n.tr("本机号码已隐藏") : value
    }

    func simIdentifier(_ value: String?, unavailable: String? = nil) -> String {
        let resolvedUnavailable = unavailable ?? L10n.tr("尚未读取")
        guard let value = nonempty(value) else { return resolvedUnavailable }
        return isEnabled ? L10n.tr("标识已隐藏") : value
    }

    private func aliasCode(for value: String) -> String {
        let normalized = PhoneNumberNormalizer.conversationID(for: value)
        let input = "\(aliasSalt)|\(normalized)"
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
        var code = ""
        var remainder = hash
        for _ in 0 ..< 3 {
            code.append(alphabet[Int(remainder % UInt64(alphabet.count))])
            remainder /= UInt64(alphabet.count)
        }
        return code
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
