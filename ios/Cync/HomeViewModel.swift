import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var result: PredictResult?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let api = APIClient()

    func predict() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            result = try await api.predict(text: inputText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
