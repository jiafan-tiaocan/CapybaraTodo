import SwiftUI

struct WalkingCapybaraLogo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stepDuration = 0.18
    private let gait: [(x: CGFloat, y: CGFloat)] = [
        (0, 0),
        (0.5, -1),
        (1, 0),
        (0.5, -1)
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: stepDuration)) { context in
            let pose = gait[poseIndex(at: context.date)]

            Image(nsImage: PixelCapybaraLogo.image)
                .interpolation(.none)
                .resizable()
                .frame(width: 42, height: 28)
                .offset(x: pose.x, y: pose.y)
        }
        .frame(width: 43, height: 29, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }

    private func poseIndex(at date: Date) -> Int {
        guard !reduceMotion else { return 0 }
        return Int(date.timeIntervalSinceReferenceDate / stepDuration) % gait.count
    }
}
