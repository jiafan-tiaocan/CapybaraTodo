import SwiftUI

struct TodoView: View {
    @ObservedObject var model: TodoModel
    @State private var newTodo = ""
    @State private var isHovering = false
    @State private var showCompleted = false
    private let documentPoller = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(12)
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(isHovering ? 0.28 : 0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .onHover { isHovering = $0 }
        .onReceive(documentPoller) { _ in model.reloadIfChanged() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("待办")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Text("\(model.activeItems.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
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
                                    .font(.system(size: 13))
                                    .padding(.top, 2)
                            }
                            .buttonStyle(.plain)
                            .help("标记为已完成")
                            Text(item.title)
                                .font(.system(size: 13))
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 3)
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
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                        .buttonStyle(.plain)
                        .help("恢复到进行中")
                        Text(item.title)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 3)
                }
            } label: {
                Text("已完成 \(model.completedCount)")
                    .font(.system(size: 12, weight: .medium))
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
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private var addField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("添加待办…", text: $newTodo)
                .textFieldStyle(.plain)
                .onSubmit(addTodo)
            if !newTodo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: addTodo) {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9))
    }

    private func addTodo() {
        model.add(title: newTodo)
        newTodo = ""
    }
}
