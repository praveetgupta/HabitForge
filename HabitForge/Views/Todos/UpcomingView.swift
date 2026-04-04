import SwiftUI

struct UpcomingView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.upcomingTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Upcoming")
    }
}
