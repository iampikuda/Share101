//
//  ShareViewController.swift
//  ShareExtension101Share
//
//  Created by Oluwadamisi Pikuda on 24/04/2020.
//  Copyright © 2020 Damisi Pikuda. All rights reserved.
//

import UIKit
import Social
import CoreServices

class ShareViewController: UIViewController {

    // Courtesy: https://stackoverflow.com/a/44499222/13363449 👇🏾
    // Function must be named exactly like this so a selector can be found by the compiler!
    // Anyway - it's another selector in another instance that would be "performed" instead.
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 1
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first else {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                return
        }
        let typeText = String(kUTTypeText)
        let typeURL = String(kUTTypeURL)

        // 2
        if itemProvider.hasItemConformingToTypeIdentifier(typeText) {
            itemProvider.loadItem(forTypeIdentifier: typeText, options: nil) { (item, error) in
                if let error = error { print("Text-Error: \(error.localizedDescription)") }


                if let text = item as? String {
                    do {// 2.1
                        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                        let matches = detector.matches(
                            in: text,
                            options: [],
                            range: NSRange(location: 0, length: text.utf16.count)
                        )
                        // 2.2
                        if let firstMatch = matches.first, let range = Range(firstMatch.range, in: text) {
                            UserDefaults(suiteName: "group.ShareExtension101")?.set(text[range], forKey: "incomingURL")
                        }
                    } catch let error {
                        print("Do-Try Error: \(error.localizedDescription)")
                    }
                }

                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
                    guard let url = URL(string: "ShareExtension101://") else { return }
                    _ = self.openURL(url)
                })
            }
        // 3
        } else if itemProvider.hasItemConformingToTypeIdentifier(typeURL) {
            itemProvider.loadItem(forTypeIdentifier: typeURL, options: nil) { (item, error) in
                if let error = error { print("URL-Error: \(error.localizedDescription)") }

                if let url = item as? NSURL, let urlString = url.absoluteString {
                    UserDefaults(suiteName: "group.ShareExtension101")?.set(urlString, forKey: "incomingURL")
                }

                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
                    guard let url = URL(string: "ShareExtension101://") else { return }
                    _ = self.openURL(url)
                })
            }
        } else {
            print("Error: No url or text found")
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
