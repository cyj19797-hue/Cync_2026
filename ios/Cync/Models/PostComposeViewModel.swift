//
//  PostComposeViewModel.swift
//  Cync
//
//  State for `PostComposeView`, shared by every compose mode. Doesn't know
//  which API it posts to — `PostComposeConfiguration.submit` does.
//

import Combine
import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class PostComposeViewModel: ObservableObject {
    @Published var title: String
    @Published var content: String
    /// In modes that remember it, starts from the last choice made (unchecked
    /// the first time, as in Figma). Kept apart from the comment box's own
    /// remembered choice.
    @Published var isAnonymous: Bool {
        didSet {
            if configuration.remembersAnonymousChoice {
                UserDefaults.standard.set(isAnonymous, forKey: Self.anonymousKey)
            }
        }
    }
    @Published var errorMessage: String?
    @Published var isSubmitting = false

    /// Photo picked in the 사진 첨부 row, already shrunk to a ≤1MB JPEG.
    @Published private(set) var attachedImage: Data?
    /// Decoding/shrinking a picked photo — the submit button waits for it.
    @Published private(set) var isPreparingImage = false
    /// Bound to the `PhotosPicker`; picking starts `prepareImage`.
    @Published var pickerItem: PhotosPickerItem? {
        didSet {
            if let pickerItem { prepareImage(from: pickerItem) }
        }
    }

    let configuration: PostComposeConfiguration

    private static let anonymousKey = "postComposePostsAnonymously"

    init(configuration: PostComposeConfiguration) {
        self.configuration = configuration
        title = configuration.initialTitle
        content = configuration.initialContent
        isAnonymous = configuration.remembersAnonymousChoice
            ? UserDefaults.standard.bool(forKey: Self.anonymousKey)
            : false
    }

    var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isContentEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSubmit: Bool {
        !isTitleEmpty && !isContentEmpty
    }

    /// Anything changed from what the screen opened with (even only
    /// spaces) — leaving then asks first. For a new post that's "anything
    /// typed at all".
    var hasInput: Bool {
        title != configuration.initialTitle || content != configuration.initialContent || attachedImage != nil
    }

    /// Busy with the photo or the upload — the submit button is disabled.
    var isBusy: Bool { isSubmitting || isPreparingImage }

    /// X on a newly picked photo. In edit mode this goes back to showing
    /// the notice's existing image.
    func removeAttachedImage() {
        attachedImage = nil
        pickerItem = nil
    }

    private func prepareImage(from item: PhotosPickerItem) {
        isPreparingImage = true
        Task {
            defer {
                isPreparingImage = false
                // Lets the same photo be picked again after an X.
                pickerItem = nil
            }
            do {
                guard let original = try await item.loadTransferable(type: Data.self) else {
                    throw UploadImagePreparer.PrepareError.unreadable
                }
                attachedImage = try await UploadImagePreparer.jpegData(from: original)
            } catch let error as UploadImagePreparer.PrepareError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = String(appLocalized: .composeImageLoadFailed)
            }
        }
    }

    /// Returns whether it went through (the screen then closes).
    func submit() async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }
        let draft = PostComposeDraft(
            title: title,
            content: content,
            isAnonymous: configuration.showsAnonymousToggle && isAnonymous,
            image: configuration.showsImageAttachment ? attachedImage : nil
        )
        do {
            try await configuration.submit(draft)
            return true
        } catch {
            errorMessage = configuration.failureMessage(error.localizedDescription)
            return false
        }
    }
}
