//
//  PostTranslation.swift
//  Cync
//
//  "번역 보기" on "5-1 게시글". The notice board's translation is meant to
//  come from the server (`Notice.translatedText`), but no translation
//  endpoint exists in the backend yet — so community posts are translated
//  on-device with Apple's Translation framework instead: free, no server
//  cost, and only run when someone actually taps the button. It needs
//  iOS 18 (the app supports 17), so on 17 the button is simply hidden.
//
//  `TranslationSession` can only be obtained from SwiftUI's
//  `.translationTask` modifier, so the work is split in two:
//    - `CommunityPostDetailViewModel` owns the state (original / loading /
//      translated) and the cache, and bumps `translationRequestID` to ask
//      for a translation.
//    - `.postTranslationTask(...)` below hosts the session and reports the
//      result back.
//  Swapping in a server API later only means replacing the modifier with a
//  `CyncAPI` call inside the view model; the UI and cache stay the same.
//
//  The first translation into a language may show the system's language
//  download prompt — that sheet belongs to the Translation framework and
//  can't be restyled.
//

import NaturalLanguage
import SwiftUI
import Translation

struct TranslatedPost: Equatable {
    let title: String
    let content: String
}

enum PostTranslation {
    static var isSupported: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }

    /// Whether a post is worth offering "번역 보기" for: hidden when the
    /// text is already in the reader's language (a Korean post on a Korean
    /// device). Undetectable text (very short, emoji-only) still gets it.
    static func needsTranslation(_ text: String) -> Bool {
        guard isSupported else { return false }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage,
              let deviceCode = AppLanguage.currentLocale.language.languageCode?.identifier
        else { return true }
        return Locale.Language(identifier: detected.rawValue).languageCode?.identifier != deviceCode
    }
}

/// In-memory cache so reopening the same post during this app session
/// shows its translation instantly instead of translating again. Keyed by
/// post id + last edit time + target language, so an edited post or a
/// changed device language never shows a stale result.
@MainActor
final class PostTranslationCache {
    static let shared = PostTranslationCache()
    private var storage: [String: TranslatedPost] = [:]

    private init() {}

    static func key(for post: CommunityPost) -> String {
        let target = AppLanguage.currentLocale.language.minimalIdentifier
        return "\(post.id)-\(post.updatedAt.timeIntervalSince1970)-\(target)"
    }

    subscript(post: CommunityPost) -> TranslatedPost? {
        get { storage[Self.key(for: post)] }
        set { storage[Self.key(for: post)] = newValue }
    }
}

extension View {
    /// Translates `texts` into the device language each time `requestID`
    /// changes, then calls `onResult` with the translations in the same
    /// order. No-op below iOS 18.
    func postTranslationTask(
        requestID: Int,
        texts: [String],
        onResult: @escaping @MainActor (Result<[String], Error>) -> Void
    ) -> some View {
        modifier(PostTranslationTaskModifier(requestID: requestID, texts: texts, onResult: onResult))
    }
}

private struct PostTranslationTaskModifier: ViewModifier {
    let requestID: Int
    let texts: [String]
    let onResult: @MainActor (Result<[String], Error>) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.modifier(SessionHost(requestID: requestID, texts: texts, onResult: onResult))
        } else {
            content
        }
    }
}

@available(iOS 18.0, *)
private struct SessionHost: ViewModifier {
    let requestID: Int
    let texts: [String]
    let onResult: @MainActor (Result<[String], Error>) -> Void

    @State private var configuration: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .translationTask(configuration) { session in
                let requests = texts.enumerated().map { index, text in
                    TranslationSession.Request(sourceText: text, clientIdentifier: String(index))
                }
                do {
                    let responses = try await session.translations(from: requests)
                    // Responses carry the request's identifier back, so
                    // re-sort rather than trusting arrival order.
                    let ordered = responses
                        .sorted { Int($0.clientIdentifier ?? "") ?? 0 < Int($1.clientIdentifier ?? "") ?? 0 }
                        .map(\.targetText)
                    onResult(.success(ordered))
                } catch {
                    onResult(.failure(error))
                }
            }
            .onChange(of: requestID) { _, _ in
                if configuration == nil {
                    // `source: nil` lets the framework detect the language.
                    configuration = .init(source: nil, target: AppLanguage.currentLocale.language)
                } else {
                    configuration?.invalidate()
                }
            }
    }
}
