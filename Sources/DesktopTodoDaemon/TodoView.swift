import SwiftUI

struct TodoView: View {
    @ObservedObject var model: TodoModel
    let onHide: () -> Void
    let onCompletedExpansionChanged: (Bool) -> Void
    @State private var newTodo = ""
    @State private var isHovering = false
    @State private var showCompleted = false
    @State private var editingItemID: UUID?
    @State private var editingTitle = ""
    @State private var hoveredDragHandleID: UUID?
    @State private var dropTargetItemID: UUID?
    @FocusState private var focusedEditorID: UUID?
    private let documentPoller = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()

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
        .onChange(of: showCompleted) { _, isExpanded in
            onCompletedExpansionChanged(isExpanded)
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
            .help("收起到菜单栏")
            Menu {
                Button("打开记录文档", action: model.openDocument)
                Button("更换记录文档…", action: model.chooseDocument)
                Button("重新载入", action: model.reload)
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
            LazyVStack(alignment: .leading, spacing: 2) {
                if model.activeItems.isEmpty {
                    Text("没有待办事项")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 70)
                } else {
                    ForEach(model.activeItems) { item in
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
                                itemActionsMenu(for: item)
                            }
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
                    }
                }

                completedSection
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var completedSection: some View {
        if model.completedCount > 0 {
            Divider().opacity(0.18).padding(.vertical, 4)
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    showCompleted.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(showCompleted ? 90 : 0))
                    Text("已完成 \(model.completedCount)")
                        .font(.system(size: 13, weight: .medium))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(showCompleted ? "收起已完成" : "展开已完成")

            if showCompleted {
                ForEach(model.completedItems) { item in
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
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }
            }
        }
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
            if item.completedAt != nil {
                Button("恢复到进行中", systemImage: "arrow.uturn.backward") {
                    model.restore(item)
                }
            }
            Divider()
            Button("删除", systemImage: "trash", role: .destructive) {
                if editingItemID == item.id {
                    cancelEditing()
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
        .help("编辑或删除")
    }

    private func beginEditing(_ item: TodoItem) {
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
