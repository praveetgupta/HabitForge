import SwiftUI
import Charts

struct HabitChartView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Last 30 Days")
                .font(.headline)
            
            // TODO: Implement bar chart with Swift Charts
            // See HabitForge-Habit-Module.md for chartData()
            Text("Chart placeholder")
                .foregroundStyle(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}
