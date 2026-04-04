import SwiftUI

struct AnytimeView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.anytimeTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Anytime")
    }
}
