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
    /// The `extraToggle` switch (when the mode has one).
    @Published var extraToggleValue: Bool
    /// 행사 날짜 (when the mode has the section). `nil` = no date.
    @Published private(set) var eventDate: EventDateSelection?
    /// Which row's calendar is open — at most one.
    @Published private(set) var expandedEventDateField: EventDateField?
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
        extraToggleValue = configuration.extraToggle?.initialValue ?? false
        eventDate = configuration.eventDate?.initialSelection
        expandedEventDateField = configuration.eventDate?.initialExpandedField
        isAnonymous = configuration.remembersAnonymousChoice
            ? UserDefaults.standard.bool(forKey: Self.anonymousKey)
            : false
    }

    #if DEBUG
    /// `-debugEventDate` / `-debugComposeAutoSubmit` (MockServer.swift).
    func applyDebugLaunchState() {
        guard configuration.eventDate != nil else { return }
        let today = EventDateFormat.day(Date())
        switch MockServer.eventDateState {
        case "start":
            eventDate = EventDateSelection(start: today)
            expandedEventDateField = .start
        case "end":
            eventDate = EventDateSelection(start: today, end: Calendar.current.date(byAdding: .day, value: 3, to: today))
            expandedEventDateField = .end
        case "clear":
            clearEventDate()
        default:
            break
        }
        if MockServer.autoSubmitsCompose {
            if isTitleEmpty { title = "학생회 행사 안내" }
            if isContentEmpty { content = "행사 날짜 확인용 공지입니다." }
        }
    }
    #endif

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
            || extraToggleValue != (configuration.extraToggle?.initialValue ?? false)
            || isEventDateChanged
    }

    // MARK: - 행사 날짜

    private var isEventDateChanged: Bool {
        eventDate?.normalized != configuration.eventDate?.initialSelection
    }

    /// What the draft sends: nothing when unchanged (edit: the server keeps
    /// it), `.clear` when an existing date was removed, else `.set`.
    var eventDateChange: EventDateChange {
        guard configuration.eventDate != nil, isEventDateChanged else { return .none }
        guard let selection = eventDate?.normalized else { return .clear }
        return .set(start: selection.start, end: selection.end)
    }

    /// "행사 날짜 추가" — today as a one-day event, with its calendar open.
    func addEventDate() {
        eventDate = EventDateSelection(start: EventDateFormat.day(Date()))
        expandedEventDateField = .start
    }

    func clearEventDate() {
        eventDate = nil
        expandedEventDateField = nil
    }

    /// Tapping a 시작일/마감일 row opens its calendar (closing the other),
    /// or closes it if already open.
    func toggleEventCalendar(_ field: EventDateField) {
        expandedEventDateField = expandedEventDateField == field ? nil : field
    }

    func collapseEventCalendar() {
        expandedEventDateField = nil
    }

    /// 기간으로 설정 on: 마감일 starts at the start day. Off: one-day event.
    func setEventDateRange(_ isRange: Bool) {
        guard var selection = eventDate else { return }
        selection.end = isRange ? selection.start : nil
        eventDate = selection
        if !isRange, expandedEventDateField == .end { expandedEventDateField = nil }
    }

    /// A day picked in `field`'s calendar; the calendar then folds. A start
    /// moved past the end drags the end along; an end before the start is
    /// ignored (those days are disabled anyway).
    func selectEventDay(_ date: Date, for field: EventDateField) {
        guard var selection = eventDate else { return }
        let day = EventDateFormat.day(date)
        switch field {
        case .start:
            selection.start = day
            if let end = selection.end, end < day { selection.end = day }
        case .end:
            guard day >= selection.start else { return }
            selection.end = day
        }
        eventDate = selection
        expandedEventDateField = nil
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
            image: configuration.showsImageAttachment ? attachedImage : nil,
            extraToggle: configuration.extraToggle != nil && extraToggleValue,
            eventDate: eventDateChange
        )
        do {
            try await configuration.submit(draft)
            return true
        } catch let error as PostComposeDisplayError {
            errorMessage = error.message
            return false
        } catch {
            errorMessage = configuration.failureMessage(error.localizedDescription)
            return false
        }
    }
}
