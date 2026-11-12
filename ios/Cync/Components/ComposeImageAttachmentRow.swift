//
//  ComposeImageAttachmentRow.swift
//  Cync
//
//  "사진 첨부" row on `PostComposeView` (학생회 공지 modes only), sitting
//  where the community's 익명 row does. One photo:
//    - nothing yet:     [photo icon] 사진 첨부
//    - picked:          thumbnail with an X (cancels the pick) + 사진 변경
//    - edit, existing:  the notice's current image (no X — the server can't
//                       delete an image, only replace it) + 사진 변경 +
//                       a line saying so
//  Picking uses the system `PhotosPicker` (approved): it runs out of
//  process and needs no photo-library permission, so Info.plist has no
//  usage string for it.
//

import PhotosUI
import SwiftUI

struct ComposeImageAttachmentRow: View {
    @Binding var pickerItem: PhotosPickerItem?
    /// Newly picked photo (≤1MB JPEG), if any.
    let attachedImage: Data?
    /// Edit mode: the notice's current image.
    let existingImageURL: URL?
    let isPreparing: Bool
    let onRemove: () -> Void

    static let rowHeight: CGFloat = 44
    private static let thumbnailSize: CGFloat = 64
    private static let removeButtonSize: CGFloat = 20

    private var hasPreview: Bool { attachedImage != nil || existingImageURL != nil }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.cardInset) {
            if let attachedImage, let image = UIImage(data: attachedImage) {
                thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .overlay(alignment: .topTrailing) { removeButton }
            } else if let existingImageURL {
                thumbnail {
                    RemoteImage(url: existingImageURL)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                picker
                if attachedImage == nil && existingImageURL != nil {
                    Text(.composeImageReplaceOnlyHint)
                        .font(.noticeDate).tracking(Tracking.noticeDate)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
        .padding(.vertical, hasPreview ? Spacing.xs : 0)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var picker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: Spacing.xs) {
                if isPreparing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.textSecondary)
                } else {
                    Image(systemName: "photo")
                        .font(.categoryBadge)
                }
                Text(hasPreview ? .composeImageChange : .composeImageAttach)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
            }
            .foregroundStyle(Color.textSecondary)
            .frame(minHeight: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isPreparing)
    }

    private func thumbnail<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.inputField))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.inputField)
                    .stroke(Color.borderLight)
            }
            .accessibilityElement()
            .accessibilityLabel(Text(.composeImagePreview))
    }

    /// 20pt to look at, 44pt to tap.
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark")
                .font(.noticeDate)
                .fontWeight(.bold)
                .imageScale(.small)
                .foregroundStyle(Color.white)
                .frame(width: Self.removeButtonSize, height: Self.removeButtonSize)
                .background(Circle().fill(Color.gray700))
                .padding((44 - Self.removeButtonSize) / 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: 44 / 2 - Spacing.xxs, y: -(44 / 2 - Spacing.xxs))
        .accessibilityLabel(Text(.composeImageRemove))
    }
}

/// A public image URL with a placeholder while loading or on failure —
/// shared by the compose preview and the notice detail.
struct RemoteImage: View {
    let url: URL
    var contentMode: ContentMode = .fill
    /// Fixed placeholder height, for layouts that don't size the view
    /// themselves (e.g. inside a ScrollView). `nil` fills the given frame.
    var placeholderHeight: CGFloat? = nil

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(systemImage: "photo")
            default:
                placeholder(systemImage: nil)
            }
        }
    }

    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            Color.surface
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.categoryBadge)
                    .foregroundStyle(Color.gray400)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.gray400)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: placeholderHeight)
    }
}
