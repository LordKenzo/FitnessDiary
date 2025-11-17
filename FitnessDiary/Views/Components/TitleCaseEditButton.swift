import SwiftUI

/// A custom edit button that mirrors SwiftUI's EditButton behavior
/// but keeps the label in title case instead of all caps.
struct TitleCaseEditButton: View {
    @Environment(\.editMode) private var editMode

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        Button(action: toggleEditMode) {
            Text(isEditing ? "Fine" : "Modifica")
        }
    }

    private func toggleEditMode() {
        guard let editMode else { return }
        withAnimation {
            editMode.wrappedValue = isEditing ? .inactive : .active
        }
    }
}

private extension EditMode {
    var isEditing: Bool {
        self == .active
    }
}
