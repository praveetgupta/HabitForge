import Foundation
import SwiftData

struct SeedExercise {
    let name: String
    let muscleGroup: String
    let equipmentType: String
    let exerciseType: String
}

/// Seed library inserted on first launch when `Exercise` count is 0.
/// Muscle groups, equipment types and exercise types must match the string
/// conventions in HANDOFF.md Section 5.
enum ExerciseSeedData {
    static let muscleGroups = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms",
        "Core", "Quads", "Hamstrings", "Glutes", "Calves", "Cardio"
    ]

    static let equipmentTypes = [
        "Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight",
        "Kettlebell", "Band", "Smith", "Other"
    ]

    static let exerciseTypes = ["Weighted", "Bodyweight", "Timed", "Cardio"]

    static let exercises: [SeedExercise] = [
        // Chest
        SeedExercise(name: "Barbell Bench Press", muscleGroup: "Chest", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Incline Barbell Bench Press", muscleGroup: "Chest", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Decline Barbell Bench Press", muscleGroup: "Chest", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Dumbbell Bench Press", muscleGroup: "Chest", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Incline Dumbbell Press", muscleGroup: "Chest", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Dumbbell Fly", muscleGroup: "Chest", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Cable Crossover", muscleGroup: "Chest", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Chest Press Machine", muscleGroup: "Chest", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Pec Deck Machine", muscleGroup: "Chest", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Push-Up", muscleGroup: "Chest", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),

        // Back
        SeedExercise(name: "Deadlift", muscleGroup: "Back", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Barbell Row", muscleGroup: "Back", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "T-Bar Row", muscleGroup: "Back", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Dumbbell Row", muscleGroup: "Back", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Lat Pulldown", muscleGroup: "Back", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Pull-Up", muscleGroup: "Back", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Chin-Up", muscleGroup: "Back", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Seated Cable Row", muscleGroup: "Back", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Straight-Arm Pulldown", muscleGroup: "Back", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Face Pull", muscleGroup: "Back", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Single-Arm Lat Pulldown", muscleGroup: "Back", equipmentType: "Cable", exerciseType: "Weighted"),

        // Shoulders
        SeedExercise(name: "Overhead Press", muscleGroup: "Shoulders", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Seated Dumbbell Shoulder Press", muscleGroup: "Shoulders", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Arnold Press", muscleGroup: "Shoulders", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Lateral Raise", muscleGroup: "Shoulders", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Cable Lateral Raise", muscleGroup: "Shoulders", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Front Raise", muscleGroup: "Shoulders", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Rear Delt Fly", muscleGroup: "Shoulders", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Machine Shoulder Press", muscleGroup: "Shoulders", equipmentType: "Machine", exerciseType: "Weighted"),

        // Biceps
        SeedExercise(name: "Barbell Curl", muscleGroup: "Biceps", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "EZ-Bar Curl", muscleGroup: "Biceps", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Dumbbell Curl", muscleGroup: "Biceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Hammer Curl", muscleGroup: "Biceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Incline Dumbbell Curl", muscleGroup: "Biceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Preacher Curl Machine", muscleGroup: "Biceps", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Cable Curl", muscleGroup: "Biceps", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Concentration Curl", muscleGroup: "Biceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),

        // Triceps
        SeedExercise(name: "Close-Grip Bench Press", muscleGroup: "Triceps", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Triceps Pushdown", muscleGroup: "Triceps", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Overhead Cable Extension", muscleGroup: "Triceps", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Lying Triceps Extension", muscleGroup: "Triceps", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Dumbbell Overhead Triceps Extension", muscleGroup: "Triceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Dip", muscleGroup: "Triceps", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Triceps Kickback", muscleGroup: "Triceps", equipmentType: "Dumbbell", exerciseType: "Weighted"),

        // Forearms
        SeedExercise(name: "Wrist Curl", muscleGroup: "Forearms", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Reverse Wrist Curl", muscleGroup: "Forearms", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Reverse Curl", muscleGroup: "Forearms", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Farmer's Carry", muscleGroup: "Forearms", equipmentType: "Kettlebell", exerciseType: "Weighted"),

        // Core
        SeedExercise(name: "Plank", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Timed"),
        SeedExercise(name: "Side Plank", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Timed"),
        SeedExercise(name: "Hanging Leg Raise", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Ab Wheel Rollout", muscleGroup: "Core", equipmentType: "Other", exerciseType: "Bodyweight"),
        SeedExercise(name: "Cable Crunch", muscleGroup: "Core", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Crunch", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Russian Twist", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Dead Bug", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Mountain Climbers", muscleGroup: "Core", equipmentType: "Bodyweight", exerciseType: "Cardio"),

        // Quads
        SeedExercise(name: "Back Squat", muscleGroup: "Quads", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Front Squat", muscleGroup: "Quads", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Goblet Squat", muscleGroup: "Quads", equipmentType: "Kettlebell", exerciseType: "Weighted"),
        SeedExercise(name: "Leg Press", muscleGroup: "Quads", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Hack Squat", muscleGroup: "Quads", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Leg Extension", muscleGroup: "Quads", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Bulgarian Split Squat", muscleGroup: "Quads", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Walking Lunge", muscleGroup: "Quads", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Smith Machine Squat", muscleGroup: "Quads", equipmentType: "Smith", exerciseType: "Weighted"),

        // Hamstrings
        SeedExercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Single-Leg Romanian Deadlift", muscleGroup: "Hamstrings", equipmentType: "Dumbbell", exerciseType: "Weighted"),
        SeedExercise(name: "Lying Leg Curl", muscleGroup: "Hamstrings", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Seated Leg Curl", muscleGroup: "Hamstrings", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Nordic Curl", muscleGroup: "Hamstrings", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Good Morning", muscleGroup: "Hamstrings", equipmentType: "Barbell", exerciseType: "Weighted"),

        // Glutes
        SeedExercise(name: "Hip Thrust", muscleGroup: "Glutes", equipmentType: "Barbell", exerciseType: "Weighted"),
        SeedExercise(name: "Glute Bridge", muscleGroup: "Glutes", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),
        SeedExercise(name: "Cable Kickback", muscleGroup: "Glutes", equipmentType: "Cable", exerciseType: "Weighted"),
        SeedExercise(name: "Hip Abduction Machine", muscleGroup: "Glutes", equipmentType: "Machine", exerciseType: "Weighted"),

        // Calves
        SeedExercise(name: "Standing Calf Raise", muscleGroup: "Calves", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Seated Calf Raise", muscleGroup: "Calves", equipmentType: "Machine", exerciseType: "Weighted"),
        SeedExercise(name: "Single-Leg Calf Raise", muscleGroup: "Calves", equipmentType: "Bodyweight", exerciseType: "Bodyweight"),

        // Cardio & conditioning
        SeedExercise(name: "Treadmill Run", muscleGroup: "Cardio", equipmentType: "Machine", exerciseType: "Cardio"),
        SeedExercise(name: "Indoor Cycling", muscleGroup: "Cardio", equipmentType: "Machine", exerciseType: "Cardio"),
        SeedExercise(name: "Rowing Machine", muscleGroup: "Cardio", equipmentType: "Machine", exerciseType: "Cardio"),
        SeedExercise(name: "Elliptical", muscleGroup: "Cardio", equipmentType: "Machine", exerciseType: "Cardio"),
        SeedExercise(name: "Stair Climber", muscleGroup: "Cardio", equipmentType: "Machine", exerciseType: "Cardio"),
        SeedExercise(name: "Jump Rope", muscleGroup: "Cardio", equipmentType: "Other", exerciseType: "Cardio"),
        SeedExercise(name: "Burpee", muscleGroup: "Cardio", equipmentType: "Bodyweight", exerciseType: "Cardio"),
        SeedExercise(name: "Kettlebell Swing", muscleGroup: "Cardio", equipmentType: "Kettlebell", exerciseType: "Weighted"),
        SeedExercise(name: "Battle Ropes", muscleGroup: "Cardio", equipmentType: "Other", exerciseType: "Cardio")
    ]

    /// Inserts the library if the store has no exercises. Returns true if seeded.
    @discardableResult
    static func seedIfNeeded(modelContext: ModelContext) -> Bool {
        let count = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard count == 0 else { return false }
        for seed in exercises {
            let e = Exercise(
                name: seed.name,
                muscleGroup: seed.muscleGroup,
                equipmentType: seed.equipmentType,
                exerciseType: seed.exerciseType,
                isCustom: false
            )
            modelContext.insert(e)
        }
        try? modelContext.save()
        return true
    }
}
