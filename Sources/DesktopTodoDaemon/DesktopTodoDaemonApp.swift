import AppKit
import Combine
import SwiftUI

enum TodoPanelLayout {
    static let width: CGFloat = 468
    static let maximumHeight: CGFloat = 780
}

@main
struct DesktopTodoDaemonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
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
    private var statusItem: NSStatusItem?
    private var visibilityMenuItem: NSMenuItem?
    private var pendingRestartSectionExpanded = false
    private var completedSectionExpanded = false
    private var measuredListContentHeight: CGFloat?
    private let panelWidth = TodoPanelLayout.width

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        let model = TodoModel()
        self.model = model
        activeCount = model.activeItems.count
        refreshStatusMenu()
        let hostingView = NSHostingView(rootView: TodoView(
            model: model,
            onHide: { [weak self] in
                self?.hidePanel()
            },
            onSectionExpansionChanged: { [weak self] pendingRestartExpanded, completedExpanded in
                self?.pendingRestartSectionExpanded = pendingRestartExpanded
                self?.completedSectionExpanded = completedExpanded
                self?.resizePanelToFitContent()
            },
            onListContentHeightChanged: { [weak self] height in
                guard let self else { return }
                let stableHeight = ceil(height)
                guard abs((self.measuredListContentHeight ?? 0) - stableHeight) > 1 else { return }
                self.measuredListContentHeight = stableHeight
                self.resizePanelToFitContent()
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
        panel.isMovableByWindowBackground = false
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
                self?.refreshStatusMenu()
            }
        }
    }

    private func configureStatusItem() {
        let autosaveName = "com.jiafan.desktop-todo-daemon.status-item"
        let preferredPositionKey = "NSStatusItem Preferred Position \(autosaveName)"
        if UserDefaults.standard.object(forKey: preferredPositionKey) == nil {
            // New status items are otherwise inserted at the far-left edge of the
            // status area, which can leave them hidden behind a MacBook notch.
            UserDefaults.standard.set(0, forKey: preferredPositionKey)
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = autosaveName
        item.isVisible = true
        if let button = item.button {
            button.image = CapybaraStatusIcon.image
            button.image?.size = NSSize(width: 18, height: 18)
            button.imagePosition = .imageLeading
            button.imageHugsTitle = true
            button.toolTip = "卡皮待办"
            button.setAccessibilityLabel("卡皮待办")
        }

        let menu = NSMenu()
        let visibilityItem = NSMenuItem(
            title: "",
            action: #selector(togglePanelVisibility),
            keyEquivalent: ""
        )
        visibilityItem.target = self
        menu.addItem(visibilityItem)

        let openDocumentItem = NSMenuItem(
            title: "打开记录文档",
            action: #selector(openTodoDocument),
            keyEquivalent: ""
        )
        openDocumentItem.target = self
        menu.addItem(openDocumentItem)

        let changeDocumentItem = NSMenuItem(
            title: "更换记录文档…",
            action: #selector(changeTodoDocument),
            keyEquivalent: ""
        )
        changeDocumentItem.target = self
        menu.addItem(changeDocumentItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出卡皮待办",
            action: #selector(terminateApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
        visibilityMenuItem = visibilityItem
        refreshStatusMenu()
    }

    private func refreshStatusMenu() {
        let action = panelVisible ? "隐藏待办" : "显示待办"
        visibilityMenuItem?.title = "\(action) · \(activeCount) 项"
        statusItem?.button?.title = "\(activeCount)"
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
            showPanel()
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showPanel()
        return false
    }

    @objc func openTodoDocument() {
        model?.openDocument()
    }

    @objc func changeTodoDocument() {
        model?.chooseDocument()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        panelVisible = false
        refreshStatusMenu()
    }

    private func showPanel() {
        panel?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        panelVisible = true
        refreshStatusMenu()
    }

    @objc private func terminateApp() {
        NSApp.terminate(nil)
    }

    private func preferredPanelHeight(for model: TodoModel) -> CGFloat {
        let visibleRows = min(max(model.activeItems.count, 1), 8)
        let rowHeight: CGFloat = 36
        let baseHeight: CGFloat = 132
        let pendingRestartHeaderHeight: CGFloat = model.pendingRestartCount > 0 ? 34 : 0
        let pendingRestartRows = pendingRestartSectionExpanded ? min(model.pendingRestartCount, 8) : 0
        let pendingRestartRowsHeight = CGFloat(pendingRestartRows) * 36
        let completedHeaderHeight: CGFloat = model.completedCount > 0 ? 34 : 0
        let completedRows = completedSectionExpanded ? min(model.recentCompletedItems.count, 8) : 0
        let completedRowsHeight = CGFloat(completedRows) * 44
        let hasFeedback = model.canUndoLastCompletion || model.canUndoLastDelete
        let undoHeight: CGFloat = hasFeedback ? 40 : 0
        let estimatedListHeight = CGFloat(visibleRows) * rowHeight
            + pendingRestartHeaderHeight
            + pendingRestartRowsHeight
            + completedHeaderHeight
            + completedRowsHeight
        let listHeight = measuredListContentHeight ?? estimatedListHeight
        let screenHeight = (panel?.screen ?? NSScreen.main)?.visibleFrame.height
            ?? TodoPanelLayout.maximumHeight
        let availableMaximum = min(TodoPanelLayout.maximumHeight, screenHeight - 48)
        return min(availableMaximum, max(190, baseHeight + listHeight + undoHeight))
    }

    private func resizePanelToFitContent() {
        guard let panel, let model else { return }
        let targetHeight = ceil(preferredPanelHeight(for: model))
        guard abs(panel.frame.height - targetHeight) > 1 else { return }

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
