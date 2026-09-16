import SwiftUI

struct TodoView: View {
    @ObservedObject var model: TodoModel
    let onHide: () -> Void
    @State private var newTodo = ""
    @State private var isHovering = false
    @State private var showCompleted = false
    private let documentPoller = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Divider().opacity(0.25)
            todoList
            if model.canUndoLastCompletion {
                undoBar
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
        .frame(width: 360)
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(isHovering ? 0.28 : 0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .onHover { isHovering = $0 }
        .onReceive(documentPoller) { _ in model.reloadIfChanged() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("待办")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("\(model.activeItems.count)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
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
    }

    @ViewBuilder
    private var todoList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if model.activeItems.isEmpty {
                    Text("没有待办事项")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 70)
                } else {
                    ForEach(model.activeItems) { item in
                        HStack(alignment: .top, spacing: 8) {
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
                            Text(item.title)
                                .font(.system(size: 15))
                                .fontWeight(item.needsHighPriorityHighlight ? .medium : .regular)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                            if item.needsHighPriorityHighlight && item.priority != .p0 {
                                Text("重点")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(highPriorityAccent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(highPriorityAccent.opacity(0.1), in: Capsule())
                            }
                            priorityMenu(for: item)
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
            DisclosureGroup(isExpanded: $showCompleted) {
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
                        Text(item.title)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }
            } label: {
                Text("已完成 \(model.completedCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .disclosureGroupStyle(.automatic)
        }
    }

    private var undoBar: some View {
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

    private var highPriorityAccent: Color {
        Color(red: 0.86, green: 0.24, blue: 0.18)
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
