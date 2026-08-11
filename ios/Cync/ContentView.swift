import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Cync")
                    .font(.largeTitle.bold())

                TextField("텍스트 입력", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Predict") {
                    Task { await viewModel.predict() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)

                if viewModel.isLoading {
                    ProgressView()
                }

                if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("label: \(result.label)")
                        Text(String(format: "score: %.2f", result.score))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
