import AppKit

enum PixelCapybaraLogo {
    static let image: NSImage = {
        let installedURL = Bundle.main.url(
            forResource: "capybara-pixel-logo",
            withExtension: "png"
        )
        let packageURL = Bundle.module.url(
            forResource: "capybara-pixel-logo",
            withExtension: "png"
        )

        guard let url = installedURL ?? packageURL,
              let image = NSImage(contentsOf: url) else {
            return NSImage(size: NSSize(width: 42, height: 28))
        }

        image.size = NSSize(width: 42, height: 28)
        image.accessibilityDescription = "眯眼像素卡皮巴拉"
        return image
    }()
}
