import SwiftUI

/// Weight is always *stored* in kilograms (`PerformedSet.weightKg`,
/// `RoutineExercise.defaultWeightKg`, `Exercise.prMaxWeight`). This enum only governs how
/// it is shown and entered, so switching units never rewrites the database.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    var id: String { rawValue }

    var shortName: String { rawValue }

    var displayName: String {
        switch self {
        case .kilograms: "Kilograms (kg)"
        case .pounds: "Pounds (lb)"
        }
    }

    private static let poundsPerKilogram = 2.2046226218

    func fromKilograms(_ kilograms: Double) -> Double {
        switch self {
        case .kilograms: kilograms
        case .pounds: kilograms * Self.poundsPerKilogram
        }
    }

    func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kilograms: value
        case .pounds: value / Self.poundsPerKilogram
        }
    }

    /// Rounded, thousands-separated, with the unit suffix — e.g. `"7,480 lb"`.
    func format(kilograms: Double) -> String {
        "\(Int(fromKilograms(kilograms).rounded()).formatted()) \(shortName)"
    }

    /// The number alone, for use next to a column header that already names the unit.
    func formatValue(kilograms: Double) -> String {
        Int(fromKilograms(kilograms).rounded()).formatted()
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, dark, light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .dark: "Dark"
        case .light: "Light"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

/// App-wide preferences, backed by `UserDefaults`. `@Observable` so SwiftUI views that read
/// a property redraw when it changes, and so non-view code (formatters, exporters) can read
/// the same values without a SwiftUI environment.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let weightUnit = "settings.weightUnit"
        static let appearance = "settings.appearance"
        static let defaultRestSeconds = "settings.defaultRestSeconds"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        weightUnit = defaults.string(forKey: Key.weightUnit)
            .flatMap(WeightUnit.init(rawValue:)) ?? .kilograms
        appearance = defaults.string(forKey: Key.appearance)
            .flatMap(AppearancePreference.init(rawValue:)) ?? .dark
        let storedRest = defaults.integer(forKey: Key.defaultRestSeconds)
        defaultRestSeconds = storedRest > 0 ? storedRest : 90
    }

    var weightUnit: WeightUnit {
        didSet { defaults.set(weightUnit.rawValue, forKey: Key.weightUnit) }
    }

    var appearance: AppearancePreference {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    /// Fallback rest length for exercises added outside a routine, where there is no
    /// per-exercise `restSeconds` to read.
    var defaultRestSeconds: Int {
        didSet { defaults.set(defaultRestSeconds, forKey: Key.defaultRestSeconds) }
    }
}
