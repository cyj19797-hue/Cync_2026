//
//  PostComposeView.swift
//  Cync
//
//  The one compose screen behind 커뮤니티 글쓰기 and 학생회 공지 작성/수정
//  (Figma "26 2 창학", frame `228:1697` "5-2 게시글 등록"). What differs per
//  mode comes in through `PostComposeConfiguration`; everything below is
//  shared, so a layout change here shows up in every mode.
//
//  Back-chevron + centered title + submit button (`228:1708`), a title
//  field (+ "익명" checkbox, community only — `228:1714`/`228:1774`), and a
//  placeholder-driven content editor (`228:1719`).
//
//  Frame-naming convention (design-to-code guide §2): a name like "…등록"
//  (not "Sheet"/"Modal") plus Figma's own back-chevron (not an X button)
//  means this is a *pushed* destination, not a `.sheet` — the back chevron
//  is the cancel/dismiss affordance; callers push it with
//  `.navigationDestination`.
//
//  Beyond Figma:
//  - The submit button is gray on `surface` until both title and content
//    are filled, then white on `buttonAccent`, like the app's other filled
//    buttons. It stays tappable
//    while gray: a tap then says what's missing in a toast and moves the
//    cursor to the empty field.
//  - Leaving (back button or edge swipe) with anything changed asks
//    "나가면 작성글이 사라집니다. 그래도 나가시겠습니까?" (취소 / 확인)
//    first; with nothing changed it just leaves.
//  - The title field is focused on open; "다음" on the keyboard moves to
//    the content.
//  - "익명" sits on its own row under the divider (it used to share the
//    title row and squeeze long titles), with what it does written beside
//    it when checked. Modes without it skip the row entirely.
//  - Cync 공지 modes put an on/off row there instead
//    (`PostComposeConfiguration.extraToggle` — "앱 실행 시 팝업으로 띄우기"
//    + a gray hint line), drawn with `AppSwitchToggleStyle`.
//  - 학생회 공지 modes put a "사진 첨부" row there instead
//    (`ComposeImageAttachmentRow`, one photo, shrunk to ≤1MB before upload).
//    The submit button waits while a photo is being prepared and shows a
//    spinner while uploading.
//  - 학생회 공지 modes also get the 행사 날짜 section between the divider
//    and 사진 첨부 (`ComposeEventDateSection`, from
//    `PostComposeConfiguration.eventDate`). Its fold-out calendar can be
//    taller than a small screen leaves, so in that mode everything above
//    the editor sits in a scroll view capped to leave the editor
//    `minEditorHeight`. Focusing the title or content folds the calendar;
//    opening a calendar drops the keyboard. Other modes keep the plain
//    stack — nothing changes for them.
//  - Vertical rhythm (kept tight): header → title 12 (as on every screen),
//    title → divider 12, divider → 익명 row 0 (the 44pt row has its own
//    air), 익명 row → content text 8. Without the 익명 row: divider →
//    content text 12, same as title → divider.
//
//  No UIKit anywhere on this screen — see PlaceholderTextEditor.swift and
//  CheckboxToggle.swift for why the two trickiest-looking controls
//  (placeholder text editor, square checkbox) still don't need it.
//

import SwiftUI

struct PostComposeView: View {
    @StateObject private var viewModel: PostComposeViewModel
    @Environment(\.dismiss) private var dismiss

    init(configuration: PostComposeConfiguration) {
        _viewModel = StateObject(wrappedValue: PostComposeViewModel(configuration: configuration))
    }

    private var configuration: PostComposeConfiguration { viewModel.configuration }

    /// A row between the divider and the content (익명, 사진 첨부 or the
    /// extra switch).
    private var hasOptionRow: Bool {
        configuration.showsAnonymousToggle || configuration.showsImageAttachment
            || configuration.extraToggle != nil || configuration.eventDate != nil
    }

    private enum Field {
        case title
        case content
    }

    @FocusState private var focusedField: Field?
    @State private var isDiscardConfirmPresented = false
    @State private var toastMessage: String?
    /// 행사 날짜 mode: height of everything above the editor, and of the
    /// area shared by it and the editor.
    @State private var topContentHeight: CGFloat = 0
    @State private var bodyAreaHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What the editor keeps when a fold-out calendar fills the top.
    private static let minEditorHeight: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: configuration.navigationTitleKey, onBack: attemptLeave) {
                submitButton
            }

            if configuration.eventDate != nil {
                VStack(spacing: 0) {
                    scrollingTopContent
                    editor
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bodyAreaHeight = $0 }
            } else {
                topContent
                editor
            }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        // With something typed, the system swipe-back is switched off (it
        // can't be intercepted) and the edge strip below takes its place,
        // asking first. With nothing typed the normal swipe works.
        .navigationBarBackButtonHidden(viewModel.hasInput)
        .overlay(alignment: .leading) {
            if viewModel.hasInput {
                edgeSwipeArea
            }
        }
        .toast(message: $toastMessage)
        .overlay {
            if isDiscardConfirmPresented {
                discardConfirm
            } else if let message = viewModel.errorMessage {
                ZStack {
                    Color.dimOverlay.ignoresSafeArea()
                    ErrorDialog(titleKey: .commonError, message: message) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDiscardConfirmPresented)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .onChange(of: focusedField) { _, field in
            // Typing in the title or content folds an open calendar.
            if field != nil, viewModel.expandedEventDateField != nil {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    viewModel.collapseEventCalendar()
                }
            }
        }
        .task {
            #if DEBUG
            viewModel.applyDebugLaunchState()
            if MockServer.autoSubmitsCompose {
                try? await Task.sleep(for: .seconds(1))
                submit()
                return
            }
            // Focusing the title would fold the calendar it just opened.
            if MockServer.eventDateState != nil { return }
            #endif
            // Wait out the push transition, or the focus doesn't take.
            try? await Task.sleep(for: .milliseconds(150))
            focusedField = .title
        }
    }

    /// Title, divider and the option rows above the editor.
    @ViewBuilder
    private var topContent: some View {
        titleRow

        Divider()
            .overlay(Color.borderLight)

        if configuration.showsAnonymousToggle {
            anonymousRow
        }

        if let extraToggle = configuration.extraToggle {
            extraToggleRow(extraToggle)
        }

        if configuration.eventDate != nil {
            eventDateSection
        }

        if configuration.showsImageAttachment {
            ComposeImageAttachmentRow(
                pickerItem: $viewModel.pickerItem,
                attachedImage: viewModel.attachedImage,
                existingImageURL: configuration.initialImageURL,
                isPreparing: viewModel.isPreparingImage,
                onRemove: viewModel.removeAttachedImage
            )
        }
    }

    /// `topContent` in a scroll view only as tall as its content, capped so
    /// the editor keeps `minEditorHeight` — with a calendar open on a small
    /// screen, the top scrolls instead of the calendar being cut off.
    private var scrollingTopContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    topContent
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    if topContentHeight == 0 || reduceMotion {
                        topContentHeight = height
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { topContentHeight = height }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.immediately)
            .frame(height: topContentHeight > 0 ? min(topContentHeight, maxTopHeight) : nil)
            .onChange(of: viewModel.expandedEventDateField) { _, field in
                guard field != nil else { return }
                // Bring the whole calendar into view once it's laid out.
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        proxy.scrollTo(ComposeEventDateSection.calendarScrollID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var maxTopHeight: CGFloat {
        guard bodyAreaHeight > 0 else { return .infinity }
        return max(bodyAreaHeight - Self.minEditorHeight, 0)
    }

    private var eventDateSection: some View {
        ComposeEventDateSection(
            selection: viewModel.eventDate,
            expandedField: viewModel.expandedEventDateField,
            onAdd: {
                focusedField = nil
                viewModel.addEventDate()
            },
            onClear: viewModel.clearEventDate,
            onToggleCalendar: { field in
                focusedField = nil
                viewModel.toggleEventCalendar(field)
            },
            onSetRange: viewModel.setEventDateRange,
            onSelect: { date, field in viewModel.selectEventDay(date, for: field) }
        )
    }

    private var editor: some View {
        // The editor fills the rest of the screen, so a tap anywhere
        // below the text starts typing too.
        PlaceholderTextEditor(
            text: $viewModel.content,
            placeholder: configuration.contentPlaceholderKey,
            font: .communityPostBody,
            placeholderColor: .textSecondary,
            textColor: .textPrimary
        )
        .focused($focusedField, equals: .content)
        .padding(.horizontal, Spacing.screenHorizontal)
        // 8pt from the 익명 / 사진 첨부 row (its 44pt row has its own
        // air), or 12pt from the divider without one, to the first line
        // of text — minus the editor's own top inset.
        .padding(
            .top,
            (hasOptionRow ? Spacing.xs : Spacing.cardInset)
                - PlaceholderTextEditor.textTopInset
        )
    }

    private var titleRow: some View {
        TextField(
            "",
            text: $viewModel.title,
            prompt: Text(configuration.titlePlaceholderKey).foregroundStyle(Color.textSecondary)
        )
        .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
        .foregroundStyle(Color.textPrimary)
        .focused($focusedField, equals: .title)
        .submitLabel(.next)
        .onSubmit { focusedField = .content }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.screenContentTop)
        .padding(.bottom, Spacing.cardInset)
    }

    /// "익명" checkbox (one 44pt-tall tap target with its label) and, when
    /// checked, what it does — beside the label, on the same 44pt row, so
    /// checking or unchecking never moves the content below.
    private var anonymousRow: some View {
        HStack(spacing: Spacing.xxs) {
            CheckboxToggle(isChecked: $viewModel.isAnonymous, titleKey: .commonAnonymous, minHeight: 44)

            if viewModel.isAnonymous {
                Text(.communityAnonymousHint)
                    .font(.noticeDate).tracking(Tracking.noticeDate)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    /// Switch + label (one tap target, 44pt tall) and an optional gray
    /// hint under it (Figma `734:4330`), then a divider before the content.
    private func extraToggleRow(_ toggle: PostComposeExtraToggle) -> some View {
        VStack(alignment: .leading, spacing: Spacing.tag) {
            Toggle(isOn: $viewModel.extraToggleValue) {
                Text(toggle.labelKey)
                    .font(.categoryChip).tracking(Tracking.categoryChip)
                    .foregroundStyle(Color.textPrimary)
            }
            .toggleStyle(AppSwitchToggleStyle())
            .frame(minHeight: 44)

            if let hintKey = toggle.hintKey {
                Text(hintKey)
                    .font(.adminFootnote).tracking(Tracking.adminFootnote)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.cardInset)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.borderLight)
        }
    }

    private static let submitButtonHeight: CGFloat = 32
    private static let submitTouchExtension = (44 - submitButtonHeight) / 2

    /// Gray until both fields are filled. 32pt tall to look at, at least
    /// 44×44pt to tap: the tappable shape reaches 6pt past the top and
    /// bottom without changing the layout.
    private var submitButton: some View {
        Button(action: submit) {
            Text(configuration.submitKey)
                .font(.headerActionButton).tracking(Tracking.headerActionButton)
                .foregroundStyle(viewModel.canSubmit ? Color.white : Color.textSecondary)
                // Uploading: a spinner in place of the label, same size.
                .opacity(viewModel.isSubmitting ? 0 : 1)
                .overlay {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.white)
                            .accessibilityLabel(Text(.composeUploading))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(minWidth: 44, minHeight: Self.submitButtonHeight)
                .background {
                    // Active: `buttonAccent`, the app's filled-button blue.
                    RoundedRectangle(cornerRadius: Radius.chipSelected)
                        .fill(viewModel.canSubmit ? Color.buttonAccent : Color.surface)
                }
                .padding(.vertical, Self.submitTouchExtension)
                .contentShape(Rectangle())
                .padding(.vertical, -Self.submitTouchExtension)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isBusy)
        .accessibilityHint(viewModel.canSubmit ? Text(verbatim: "") : Text(.communityComposeMissingFields))
    }

    private func submit() {
        guard viewModel.canSubmit else {
            toastMessage = String(appLocalized: .communityComposeMissingFields)
            focusedField = viewModel.isTitleEmpty ? .title : .content
            return
        }
        Task {
            if await viewModel.submit() {
                dismiss()
            }
        }
    }

    // MARK: - Leaving

    private func attemptLeave() {
        if viewModel.hasInput {
            focusedField = nil
            isDiscardConfirmPresented = true
        } else {
            dismiss()
        }
    }

    /// Stands in for the system swipe-back while there's input: a drag
    /// from the left edge asks before leaving. As wide as the side margin,
    /// so it never covers the text.
    private var edgeSwipeArea: some View {
        Color.clear
            .frame(width: Spacing.screenHorizontal)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        if value.translation.width > 60 && abs(value.translation.height) < value.translation.width {
                            attemptLeave()
                        }
                    }
            )
    }

    private var discardConfirm: some View {
        ZStack {
            Color.dimOverlay
                .ignoresSafeArea()
                .onTapGesture { isDiscardConfirmPresented = false }

            DialogCard {
                Text(.communityLeaveDraftTitle)
                    .font(.dialogTitle).tracking(Tracking.dialogTitle)
                    .foregroundStyle(Color.textPrimary)
                    .dialogTitleGap()

                Text(.communityLeaveDraftMessage)
                    .font(.dialogBody).tracking(Tracking.dialogBody)
                    .foregroundStyle(Color.textSecondary)
                    .dialogBodyGap()

                DialogActionRow {
                    DialogActionButton(titleKey: .commonCancel) {
                        isDiscardConfirmPresented = false
                    }
                    DialogActionButton(titleKey: .commonOk, style: .primary) {
                        isDiscardConfirmPresented = false
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .transition(.opacity)
    }
}

#Preview("커뮤니티") {
    NavigationStack {
        PostComposeView(configuration: .communityPost(onSubmit: { _ in }))
    }
}

#Preview("Cync 공지 작성 (토글 켬)") {
    NavigationStack {
        PostComposeView(configuration: .appNoticeCreate(initialPopup: true, onCreated: { _ in }))
    }
}

#Preview("Cync 공지 수정") {
    NavigationStack {
        PostComposeView(configuration: .appNoticeEdit(notice: CyncNotice(AppNotice.previewList[1]), onUpdated: { _ in }))
    }
}

#Preview("공지 작성 — 날짜 없음") {
    NavigationStack {
        PostComposeView(configuration: .councilNoticeCreate(onCreated: { _ in }))
    }
}

/// 학생회 공지 작성 with a preset 행사 날짜 (preview only).
private func councilComposePreview(
    start: Date?,
    end: Date? = nil,
    expanded: EventDateField? = nil,
    title: String = "",
    content: String = ""
) -> some View {
    var configuration = PostComposeConfiguration.councilNoticeCreate(onCreated: { _ in })
    configuration.initialTitle = title
    configuration.initialContent = content
    configuration.eventDate = PostComposeEventDateOption(initialStart: start, initialEnd: end, initialExpandedField: expanded)
    return NavigationStack { PostComposeView(configuration: configuration) }
}

private var previewToday: Date { Calendar.current.startOfDay(for: Date()) }
private func previewDay(_ offset: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: offset, to: previewToday)!
}

#Preview("공지 작성 — 하루, 달력 펼침") {
    councilComposePreview(start: previewToday, expanded: .start)
}

#Preview("공지 작성 — 기간, 마감일 달력") {
    councilComposePreview(start: previewToday, end: previewDay(4), expanded: .end)
}

#Preview("공지 수정 — 기존 기간") {
    NavigationStack {
        PostComposeView(configuration: .councilNoticeEdit(
            councilId: 1,
            title: "학생회 체육대회 참가 신청 안내",
            content: "학과 체육대회 참가 신청을 받습니다.",
            imageURL: nil,
            eventStart: previewDay(2),
            eventEnd: previewDay(4),
            onUpdated: { _ in }
        ))
    }
}

#Preview("작은 화면 — 기간, 마감일 달력", traits: .fixedLayout(width: 375, height: 667)) {
    councilComposePreview(start: previewToday, end: previewDay(4), expanded: .end, title: "체육대회 안내")
}
