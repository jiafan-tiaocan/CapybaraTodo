import AppKit
import Combine
import SwiftUI

@main
struct DesktopTodoDaemonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private var model: TodoModel?
    private var modelChangeSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = TodoModel()
        self.model = model
        let hostingView = NSHostingView(rootView: TodoView(model: model))
        let panelSize = NSSize(width: 320, height: preferredPanelHeight(for: model))
        hostingView.setFrameSize(panelSize)
        hostingView.autoresizingMask = [.width, .height]

        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.setFrameAutosaveName("DesktopTodoDaemonPanel")

        if panel.setFrameUsingName("DesktopTodoDaemonPanel") {
            let targetScreen = bestScreen(for: panel.frame) ?? NSScreen.main
            let savedTopRight = NSPoint(x: panel.frame.maxX, y: panel.frame.maxY)
            panel.setContentSize(panelSize)
            let targetFrame = NSRect(
                x: savedTopRight.x - panelSize.width,
                y: savedTopRight.y - panelSize.height,
                width: panelSize.width,
                height: panelSize.height
            )
            panel.setFrame(constrained(targetFrame, for: panel, on: targetScreen), display: false)
        } else {
            position(panel)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        modelChangeSubscription = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.resizePanelToFitContent()
            }
        }
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(
            x: visible.maxX - size.width - 24,
            y: visible.maxY - size.height - 24
        ))
    }

    private func preferredPanelHeight(for model: TodoModel) -> CGFloat {
        let visibleRows = min(max(model.activeItems.count, 1), 8)
        let rowHeight: CGFloat = 32
        let baseHeight: CGFloat = 104
        let completedHeaderHeight: CGFloat = model.completedCount > 0 ? 30 : 0
        let undoHeight: CGFloat = model.canUndoLastCompletion ? 34 : 0
        return min(420, max(170, baseHeight + CGFloat(visibleRows) * rowHeight + completedHeaderHeight + undoHeight))
    }

    private func resizePanelToFitContent() {
        guard let panel, let model else { return }
        let targetHeight = preferredPanelHeight(for: model)
        guard abs(panel.frame.height - targetHeight) > 0.5 else { return }

        let topRight = NSPoint(x: panel.frame.maxX, y: panel.frame.maxY)
        let targetFrame = NSRect(
            x: topRight.x - 320,
            y: topRight.y - targetHeight,
            width: 320,
            height: targetHeight
        )
        let targetScreen = panel.screen ?? bestScreen(for: panel.frame) ?? NSScreen.main
        panel.setFrame(constrained(targetFrame, for: panel, on: targetScreen), display: true, animate: false)
    }

    private func bestScreen(for frame: NSRect) -> NSScreen? {
        NSScreen.screens.max { left, right in
            intersectionArea(frame, left.visibleFrame) < intersectionArea(frame, right.visibleFrame)
        }
    }

    private func intersectionArea(_ left: NSRect, _ right: NSRect) -> CGFloat {
        let intersection = left.intersection(right)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }

    private func constrained(_ frame: NSRect, for panel: NSPanel, on screen: NSScreen?) -> NSRect {
        guard let screen else { return frame }
        return panel.constrainFrameRect(frame, to: screen)
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
