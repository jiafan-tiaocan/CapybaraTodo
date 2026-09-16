import AppKit
import Combine
import SwiftUI

@main
struct DesktopTodoDaemonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            Button(appDelegate.panelVisible ? "隐藏待办 · \(appDelegate.activeCount) 项" : "显示待办 · \(appDelegate.activeCount) 项") {
                appDelegate.togglePanelVisibility()
            }
            Button("打开记录文档") {
                appDelegate.openTodoDocument()
            }
            Divider()
            Button("退出桌面待办") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: CapybaraStatusIcon.image)
                .accessibilityLabel("卡皮巴拉待办")
        }
        .menuBarExtraStyle(.menu)

        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published private(set) var activeCount = 0
    @Published private(set) var panelVisible = true

    private var panel: FloatingPanel?
    private var model: TodoModel?
    private var modelChangeSubscription: AnyCancellable?
    private var completedSectionExpanded = false
    private let panelWidth: CGFloat = 360

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = TodoModel()
        self.model = model
        activeCount = model.activeItems.count
        let hostingView = NSHostingView(rootView: TodoView(
            model: model,
            onHide: { [weak self] in
                self?.hidePanel()
            },
            onCompletedExpansionChanged: { [weak self] isExpanded in
                self?.completedSectionExpanded = isExpanded
                self?.resizePanelToFitContent()
            }
        ))
        let panelSize = NSSize(width: panelWidth, height: preferredPanelHeight(for: model))
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
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenNone]
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
                self?.activeCount = self?.model?.activeItems.count ?? 0
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

    @objc func togglePanelVisibility() {
        guard let panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            panelVisible = true
        }
    }

    @objc func openTodoDocument() {
        model?.openDocument()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        panelVisible = false
    }

    private func preferredPanelHeight(for model: TodoModel) -> CGFloat {
        let visibleRows = min(max(model.activeItems.count, 1), 8)
        let rowHeight: CGFloat = 40
        let baseHeight: CGFloat = 124
        let completedHeaderHeight: CGFloat = model.completedCount > 0 ? 34 : 0
        let completedRows = completedSectionExpanded ? min(model.completedCount, 8) : 0
        let completedRowsHeight = CGFloat(completedRows) * 36
        let hasFeedback = model.canUndoLastCompletion || model.canUndoLastDelete
        let undoHeight: CGFloat = hasFeedback ? 40 : 0
        return min(
            520,
            max(
                190,
                baseHeight + CGFloat(visibleRows) * rowHeight + completedHeaderHeight + completedRowsHeight + undoHeight
            )
        )
    }

    private func resizePanelToFitContent() {
        guard let panel, let model else { return }
        let targetHeight = preferredPanelHeight(for: model)
        guard abs(panel.frame.height - targetHeight) > 0.5 else { return }

        let topRight = NSPoint(x: panel.frame.maxX, y: panel.frame.maxY)
        let targetFrame = NSRect(
            x: topRight.x - panelWidth,
            y: topRight.y - targetHeight,
            width: panelWidth,
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
