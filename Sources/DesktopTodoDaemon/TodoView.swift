import SwiftUI

struct TodoView: View {
    @ObservedObject var model: TodoModel
    let onHide: () -> Void
    let onSectionExpansionChanged: (Bool, Bool) -> Void
    let onListContentHeightChanged: (CGFloat) -> Void
    @State private var newTodo = ""
    @State private var isHovering = false
    @State private var showPendingRestart = false
    @State private var showCompleted = false
    @State private var showAllCompleted = false
    @State private var editingItemID: UUID?
    @State private var editingTitle = ""
    @State private var hoveredDragHandleID: UUID?
    @State private var dropTargetItemID: UUID?
    @State private var addingCheckpointForItemID: UUID?
    @State private var checkpointDraft = ""
    @State private var editingCheckpointID: UUID?
    @State private var editingCheckpointTitle = ""
    @FocusState private var focusedEditorID: UUID?
    @FocusState private var focusedCheckpointID: UUID?
    private let documentPoller = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Divider().opacity(0.25)
            todoList
            if model.canUndoLastDelete {
                deleteUndoBar
            } else if model.canUndoLastCompletion {
                completionUndoBar
            }
            addField
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(width: TodoPanelLayout.width)
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(isHovering ? 0.28 : 0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .onHover { isHovering = $0 }
        .onReceive(documentPoller) { _ in model.reloadIfChanged() }
        .onPreferenceChange(TodoListContentHeightKey.self) { height in
            guard height > 0 else { return }
            onListContentHeightChanged(height)
        }
        .onChange(of: showPendingRestart) { _, isExpanded in
            onSectionExpansionChanged(isExpanded, showCompleted)
        }
        .onChange(of: showCompleted) { _, isExpanded in
            onSectionExpansionChanged(showPendingRestart, isExpanded)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                WalkingCapybaraLogo()
                Text("待办")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text("\(model.activeItems.count)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .background(WindowDragArea())

            WindowDragArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: onHide) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("收起到菜单栏；再次打开应用也可恢复")
            Menu {
                Button("打开记录文档", action: model.openDocument)
                Button("更换记录文档…", action: model.chooseDocument)
                Button("重新载入", action: model.reload)
                Divider()
                Button("版本信息…", systemImage: "info.circle", action: model.showVersionInfo)
                Divider()
                Button("退出", role: .destructive) { NSApplication.shared.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .frame(height: 30)
    }

    @ViewBuilder
    private var todoList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                if model.activeItems.isEmpty {
                    VStack(spacing: 5) {
                        Text("今天还没有待办")
                            .font(.callout.weight(.medium))
                        Text("在下方输入，按回车添加第一条")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                } else {
                    ForEach(model.activeItems) { item in
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(hoveredDragHandleID == item.id ? .secondary : .tertiary)
                                    .frame(width: 18, height: 24)
                                    .contentShape(Rectangle())
                                    .onHover { isHovering in
                                        hoveredDragHandleID = isHovering ? item.id : nil
                                    }
                                    .draggable(item.id.uuidString) {
                                        Text(item.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .lineLimit(1)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    }
                                    .help("拖拽调整顺序")
                                Button {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        model.complete(item)
                                    }
                                } label: {
                                    Image(systemName: "circle")
                                        .font(.system(size: 15))
                                        .foregroundStyle(item.needsHighPriorityHighlight ? highPriorityAccent : .secondary)
                                        .padding(.top, 2)
                                }
                                .buttonStyle(.plain)
                                .help("标记为已完成")
                                itemTitle(item, completed: false)
                                Spacer(minLength: 0)
                                if editingItemID == item.id {
                                    editorControls(for: item)
                                } else if item.needsHighPriorityHighlight && item.priority != .p0 {
                                    Text("重点")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(highPriorityAccent)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(highPriorityAccent.opacity(0.1), in: Capsule())
                                }
                                if editingItemID != item.id {
                                    priorityMenu(for: item)
                                    addCheckpointButton(for: item)
                                    itemActionsMenu(for: item)
                                }
                            }
                            checkpointList(for: item, parentCompleted: false, leadingInset: 26)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .background {
                            if item.needsHighPriorityHighlight {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(highPriorityAccent.opacity(0.075))
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(highPriorityAccent)
                                            .frame(width: 3.5)
                                            .padding(.vertical, 4)
                                    }
                            }
                        }
                        .overlay {
                            if dropTargetItemID == item.id {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                            }
                        }
                        .dropDestination(for: String.self) { identifiers, _ in
                            guard let rawID = identifiers.first,
                                  let draggedID = UUID(uuidString: rawID),
                                  draggedID != item.id else {
                                dropTargetItemID = nil
                                return false
                            }
                            withAnimation(.easeOut(duration: 0.16)) {
                                model.reorderActiveItem(draggedID, relativeTo: item.id)
                            }
                            dropTargetItemID = nil
                            return true
                        } isTargeted: { isTargeted in
                            if isTargeted {
                                dropTargetItemID = item.id
                            } else if dropTargetItemID == item.id {
                                dropTargetItemID = nil
                            }
                        }
                        .id("active-\(item.id.uuidString)")
                    }
                }

                pendingRestartSection
                completedSection
            }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: TodoListContentHeightKey.self,
                        value: proxy.size.height
                    )
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var pendingRestartSection: some View {
        if model.pendingRestartCount > 0 {
            Divider().opacity(0.18).padding(.vertical, 4)
            sectionToggle(
                title: "待重启 \(model.pendingRestartCount)",
                isExpanded: showPendingRestart,
                expandedHelp: "收起待重启",
                collapsedHelp: "展开待重启"
            ) {
                showPendingRestart.toggle()
            }

            if showPendingRestart {
                ForEach(model.pendingRestartItems) { item in
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .top, spacing: 8) {
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    model.moveToActive(item)
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.orange)
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                            .help("恢复到进行中")
                            itemTitle(item, completed: false)
                            Spacer(minLength: 0)
                            if editingItemID == item.id {
                                editorControls(for: item)
                            } else {
                                priorityMenu(for: item)
                                addCheckpointButton(for: item)
                                itemActionsMenu(for: item)
                            }
                        }
                        checkpointList(for: item, parentCompleted: false, leadingInset: 18)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .background {
                        if item.needsHighPriorityHighlight {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(highPriorityAccent.opacity(0.075))
                        }
                    }
                    .id("pending-restart-\(item.id.uuidString)")
                }
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if model.completedCount > 0 {
            Divider().opacity(0.18).padding(.vertical, 4)
            sectionToggle(
                title: completedSectionTitle,
                isExpanded: showCompleted,
                expandedHelp: "收起已完成",
                collapsedHelp: "展开已完成"
            ) {
                showCompleted.toggle()
            }

            if showCompleted {
                ForEach(visibleCompletedItems) { item in
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .top, spacing: 8) {
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    model.restore(item)
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                            .help("恢复到进行中")
                            VStack(alignment: .leading, spacing: 2) {
                                itemTitle(item, completed: true)
                                if let completedAt = item.completedAt {
                                    Text("创建 \(hourText(item.createdAt)) · 完成 \(hourText(completedAt))")
                                        .font(.system(size: 11))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                            if editingItemID == item.id {
                                editorControls(for: item)
                            } else {
                                itemActionsMenu(for: item)
                            }
                        }
                        checkpointList(for: item, parentCompleted: true, leadingInset: 18)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .id("completed-\(item.id.uuidString)")
                }

                if model.olderCompletedCount > 0 {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            showAllCompleted.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: showAllCompleted ? "clock.arrow.circlepath" : "clock")
                            Text(showAllCompleted ? "仅显示近 7 天" : "查看更早的 \(model.olderCompletedCount) 项")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.plain)
                    .help(showAllCompleted ? "收起 7 天前的完成记录" : "显示全部完成记录")
                }
            }
        }
    }

    private var completedSectionTitle: String {
        if showAllCompleted {
            return "已完成 · 全部 \(model.completedCount)"
        }
        if model.olderCompletedCount > 0 {
            return "已完成 · 近 7 天 \(model.recentCompletedItems.count) · 共 \(model.completedCount)"
        }
        return "已完成 · 近 7 天 \(model.recentCompletedItems.count)"
    }

    private var visibleCompletedItems: [TodoItem] {
        showAllCompleted ? model.completedItems : model.recentCompletedItems
    }

    private func sectionToggle(
        title: String,
        isExpanded: Bool,
        expandedHelp: String,
        collapsedHelp: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18), action)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isExpanded ? expandedHelp : collapsedHelp)
    }

    private var completionUndoBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
            Text("已标记完成")
            Spacer()
            Button("撤销", action: model.undoLastCompletion)
                .buttonStyle(.plain)
                .fontWeight(.semibold)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private var deleteUndoBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "trash")
            Text("已删除")
            if let item = model.lastDeletedItem {
                Text(item.title)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button("撤销", action: model.undoLastDelete)
                .buttonStyle(.plain)
                .fontWeight(.semibold)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private var highPriorityAccent: Color {
        Color(red: 0.86, green: 0.24, blue: 0.18)
    }

    private func hourText(_ date: Date) -> String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: date
        )
        return String(
            format: "%04d-%02d-%02d %02d时",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0
        )
    }

    @ViewBuilder
    private func itemTitle(_ item: TodoItem, completed: Bool) -> some View {
        if editingItemID == item.id {
            TextField("待办内容", text: $editingTitle)
                .font(.system(size: completed ? 14 : 15))
                .textFieldStyle(.plain)
                .focused($focusedEditorID, equals: item.id)
                .onSubmit { commitEditing(item) }
                .onExitCommand(perform: cancelEditing)
        } else {
            Text(item.title)
                .font(.system(size: completed ? 14 : 15))
                .fontWeight(!completed && item.needsHighPriorityHighlight ? .medium : .regular)
                .foregroundStyle(completed ? .secondary : .primary)
                .strikethrough(completed)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func checkpointList(
        for item: TodoItem,
        parentCompleted: Bool,
        leadingInset: CGFloat
    ) -> some View {
        if !item.checkpoints.isEmpty || addingCheckpointForItemID == item.id {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(item.checkpoints) { checkpoint in
                    HStack(alignment: .top, spacing: 6) {
                        Button {
                            withAnimation(.easeOut(duration: 0.16)) {
                                model.toggleCheckpoint(checkpoint, in: item)
                            }
                        } label: {
                            Image(systemName: checkpoint.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11))
                                .foregroundStyle(checkpoint.isCompleted ? .secondary : .tertiary)
                                .frame(width: 16, height: 18)
                        }
                        .buttonStyle(.plain)
                        .help(checkpoint.isCompleted ? "恢复过程节点" : "完成过程节点")

                        if editingCheckpointID == checkpoint.id {
                            TextField("过程节点", text: $editingCheckpointTitle)
                                .font(.system(size: 12))
                                .textFieldStyle(.plain)
                                .focused($focusedCheckpointID, equals: checkpoint.id)
                                .onSubmit { commitCheckpointEditing(checkpoint, in: item) }
                                .onExitCommand(perform: cancelCheckpointEditing)
                            checkpointEditorControls(for: checkpoint, in: item)
                        } else {
                            Text(checkpoint.title)
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    parentCompleted || checkpoint.isCompleted
                                        ? Color.secondary
                                        : Color.primary.opacity(0.82)
                                )
                                .strikethrough(checkpoint.isCompleted)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            checkpointActionsMenu(for: checkpoint, in: item)
                        }
                    }
                    .padding(.vertical, 1)
                }

                if addingCheckpointForItemID == item.id {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        TextField("记录过程节点…", text: $checkpointDraft)
                            .font(.system(size: 12))
                            .textFieldStyle(.plain)
                            .focused($focusedCheckpointID, equals: item.id)
                            .onAppear {
                                DispatchQueue.main.async {
                                    focusedCheckpointID = item.id
                                }
                            }
                            .onSubmit { commitCheckpointAddition(to: item) }
                            .onExitCommand(perform: cancelCheckpointAddition)
                        Button {
                            commitCheckpointAddition(to: item)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(checkpointDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.leading, leadingInset)
            .padding(.trailing, 4)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1)
                    .padding(.leading, max(leadingInset - 9, 0))
                    .padding(.vertical, 3)
            }
        }
    }

    private func checkpointActionsMenu(for checkpoint: TodoCheckpoint, in item: TodoItem) -> some View {
        Menu {
            Button("编辑节点", systemImage: "pencil") {
                beginCheckpointEditing(checkpoint)
            }
            Divider()
            Button("删除节点", systemImage: "trash", role: .destructive) {
                model.deleteCheckpoint(checkpoint, from: item)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 18, height: 18)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("编辑或删除过程节点")
    }

    private func checkpointEditorControls(for checkpoint: TodoCheckpoint, in item: TodoItem) -> some View {
        HStack(spacing: 4) {
            Button {
                commitCheckpointEditing(checkpoint, in: item)
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .help("保存节点")

            Button(action: cancelCheckpointEditing) {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("取消修改")
        }
        .font(.system(size: 11))
    }

    private func editorControls(for item: TodoItem) -> some View {
        HStack(spacing: 5) {
            Button {
                commitEditing(item)
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .help("保存修改")

            Button(action: cancelEditing) {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("取消修改")
        }
    }

    private func itemActionsMenu(for item: TodoItem) -> some View {
        Menu {
            Button("编辑", systemImage: "pencil") {
                beginEditing(item)
            }
            if item.status != .completed {
                Button("添加过程节点", systemImage: "point.3.connected.trianglepath.dotted") {
                    beginCheckpointAddition(to: item)
                }
            }
            if item.status == .active {
                Button("移至待重启", systemImage: "arrow.clockwise") {
                    model.moveToPendingRestart(item)
                }
            } else if item.status == .pendingRestart {
                Button("恢复到进行中", systemImage: "arrow.uturn.backward") {
                    model.moveToActive(item)
                }
                Button("标记为已完成", systemImage: "checkmark.circle") {
                    model.complete(item)
                }
            } else {
                Button("恢复到进行中", systemImage: "arrow.uturn.backward") {
                    model.restore(item)
                }
            }
            Divider()
            Button("删除", systemImage: "trash", role: .destructive) {
                if editingItemID == item.id {
                    cancelEditing()
                }
                if addingCheckpointForItemID == item.id {
                    cancelCheckpointAddition()
                }
                model.delete(item)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 24)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("编辑、添加过程节点、切换状态或删除")
    }

    private func addCheckpointButton(for item: TodoItem) -> some View {
        Button {
            beginCheckpointAddition(to: item)
        } label: {
            Label("过程", systemImage: "plus.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(addingCheckpointForItemID == item.id ? Color.accentColor : .secondary)
                .padding(.horizontal, 5)
                .frame(height: 24)
                .background(.primary.opacity(0.045), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("记录这条待办的过程节点")
        .accessibilityLabel("添加过程节点")
    }

    private func beginEditing(_ item: TodoItem) {
        cancelCheckpointEditing()
        cancelCheckpointAddition()
        editingItemID = item.id
        editingTitle = item.title
        DispatchQueue.main.async {
            focusedEditorID = item.id
        }
    }

    private func commitEditing(_ item: TodoItem) {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.rename(item, title: trimmed)
        cancelEditing()
    }

    private func cancelEditing() {
        editingItemID = nil
        editingTitle = ""
        focusedEditorID = nil
    }

    private func beginCheckpointAddition(to item: TodoItem) {
        cancelEditing()
        cancelCheckpointEditing()
        addingCheckpointForItemID = item.id
        checkpointDraft = ""
        DispatchQueue.main.async {
            focusedCheckpointID = item.id
        }
    }

    private func commitCheckpointAddition(to item: TodoItem) {
        let trimmed = checkpointDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.addCheckpoint(to: item, title: trimmed)
        cancelCheckpointAddition()
    }

    private func cancelCheckpointAddition() {
        addingCheckpointForItemID = nil
        checkpointDraft = ""
        focusedCheckpointID = nil
    }

    private func beginCheckpointEditing(_ checkpoint: TodoCheckpoint) {
        cancelEditing()
        cancelCheckpointAddition()
        editingCheckpointID = checkpoint.id
        editingCheckpointTitle = checkpoint.title
        DispatchQueue.main.async {
            focusedCheckpointID = checkpoint.id
        }
    }

    private func commitCheckpointEditing(_ checkpoint: TodoCheckpoint, in item: TodoItem) {
        let trimmed = editingCheckpointTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.renameCheckpoint(checkpoint, in: item, title: trimmed)
        cancelCheckpointEditing()
    }

    private func cancelCheckpointEditing() {
        editingCheckpointID = nil
        editingCheckpointTitle = ""
        focusedCheckpointID = nil
    }

    private func priorityMenu(for item: TodoItem) -> some View {
        Menu {
            ForEach(TodoPriority.allCases, id: \.rawValue) { priority in
                Button {
                    model.setPriority(priority, for: item)
                } label: {
                    if item.priority == priority {
                        Label(priority == .none ? "无优先级" : priority.label, systemImage: "checkmark")
                    } else {
                        Text(priority == .none ? "无优先级" : priority.label)
                    }
                }
            }
        } label: {
            if item.priority == .none {
                Image(systemName: "flag")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .frame(width: 26, height: 24)
            } else {
                Text(item.priority.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(priorityColor(item.priority))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(priorityColor(item.priority).opacity(0.11), in: Capsule())
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("设置优先级")
    }

    private func priorityColor(_ priority: TodoPriority) -> Color {
        switch priority {
        case .p0: highPriorityAccent
        case .p1: Color(red: 0.82, green: 0.48, blue: 0.08)
        case .p2: Color(red: 0.19, green: 0.46, blue: 0.78)
        case .p3, .none: .secondary
        }
    }

    private var addField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("添加待办…", text: $newTodo)
                .font(.system(size: 15))
                .textFieldStyle(.plain)
                .onSubmit(addTodo)
            if !newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: addTodo) {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addTodo() {
        model.add(title: newTodo)
        newTodo = ""
    }
}

private struct TodoListContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
