import SwiftUI

struct SomedayView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.somedayTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Someday")
    }
}
