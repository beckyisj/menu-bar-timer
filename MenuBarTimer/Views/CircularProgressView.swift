import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var size: CGFloat = 160

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private let gradientColors: [Color] = [
        Color(red: 0.2, green: 0.8, blue: 0.75),
        Color(red: 0.35, green: 0.5, blue: 0.95),
        Color(red: 0.55, green: 0.35, blue: 0.95)
    ]

    private var gradient: AngularGradient {
        let sweep = max(clampedProgress, 0.001) * 360
        return AngularGradient(
            gradient: Gradient(colors: gradientColors),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(sweep)
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: clampedProgress)

            // Glow behind the ring
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth + 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
                .opacity(0.3)
                .animation(.easeInOut(duration: 0.4), value: clampedProgress)
        }
        .frame(width: size, height: size)
    }
}
