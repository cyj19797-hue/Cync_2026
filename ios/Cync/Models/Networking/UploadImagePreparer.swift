//
//  UploadImagePreparer.swift
//  Cync
//
//  Shrinks a picked photo before upload. The backend has no multipart size
//  setting, so Spring's default applies: a file over 1MB fails. Whatever
//  the original (HEIC from the camera, a huge PNG screenshot…), this
//  returns a JPEG of at most 1MB:
//    1. long side scaled down to `maxPixelLength` (never up),
//    2. JPEG quality stepped down until it fits,
//    3. still too big → dimensions shrink by 20% and try again.
//

import UIKit

enum UploadImagePreparer {
    /// Server limit per file (Spring's default `max-file-size`).
    static let maxBytes = 1_000_000
    static let maxPixelLength: CGFloat = 1600

    enum PrepareError: LocalizedError {
        /// Not an image UIKit can read.
        case unreadable
        /// Couldn't get under `maxBytes` even at the smallest size tried.
        case tooLarge

        var errorDescription: String? {
            switch self {
            case .unreadable: return String(appLocalized: .composeImageLoadFailed)
            case .tooLarge: return String(appLocalized: .composeImageTooLarge)
            }
        }
    }

    private static let qualities: [CGFloat] = [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]
    private static let minPixelLength: CGFloat = 400

    /// Runs off the main thread — decoding and re-encoding a large photo
    /// takes a noticeable moment.
    static func jpegData(from original: Data) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try prepare(original)
        }.value
    }

    private static func prepare(_ original: Data) throws -> Data {
        guard let image = UIImage(data: original) else { throw PrepareError.unreadable }

        let size = image.size
        var longSide = min(max(size.width, size.height), maxPixelLength)

        while longSide >= minPixelLength {
            let resized = resize(image, longSide: longSide)
            for quality in qualities {
                if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                    return data
                }
            }
            longSide *= 0.8
        }
        throw PrepareError.tooLarge
    }

    /// Draws at scale 1 so `longSide` is in pixels, and bakes in the
    /// photo's orientation (EXIF rotation is dropped by re-encoding).
    private static func resize(_ image: UIImage, longSide: CGFloat) -> UIImage {
        let size = image.size
        let ratio = longSide / max(size.width, size.height)
        let target = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { context in
            // JPEG has no alpha — give transparent PNGs a white page, not black.
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
