import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = .blue
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ProgressRingView(progress: 0.7, color: .green)
}
