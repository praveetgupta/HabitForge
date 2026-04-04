import SwiftUI

struct LogbookView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            // TODO: Fetch and display completed todos grouped by date
            Text("Completed tasks will appear here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Logbook")
    }
}
