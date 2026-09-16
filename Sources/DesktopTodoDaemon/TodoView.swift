import SwiftUI

struct TodoView: View {
    @ObservedObject var model: TodoModel
    @State private var newTodo = ""
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider().opacity(0.25)
            todoList
            addField
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(isHovering ? 0.28 : 0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .onHover { isHovering = $0 }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("待办")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
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
        if model.activeItems.isEmpty {
            Text("没有待办事项")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(model.activeItems) { item in
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                model.complete(item)
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle")
                                    .font(.system(size: 15))
                                    .padding(.top, 2)
                                Text(item.title)
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 7)
                            .padding(.horizontal, 5)
                        }
                        .buttonStyle(.plain)
                        .help("点击标记为已完成")
                    }
                }
            }
            .frame(maxHeight: 300)
        }
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
        .padding(10)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addTodo() {
        model.add(title: newTodo)
        newTodo = ""
    }
}

