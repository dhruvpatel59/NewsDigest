import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        // Adopts the app's Accent Color for buttons like 'Done' and the Share icon
        safariViewController.preferredControlTintColor = UIColor(named: "AccentColor")
        safariViewController.dismissButtonStyle = .close
        
        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed 
    }
}
