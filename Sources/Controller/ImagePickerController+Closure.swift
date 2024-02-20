// The MIT License (MIT)
//
// Copyright (c) 2019 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos

/// Closure convenience API.
/// Keep this simple enough for most users. More niche features can be added to ImagePickerControllerDelegate.
@objc extension UIViewController {
    
    /// Present a image picker
    ///
    /// - Parameters:
    ///   - imagePicker: The image picker to present
    ///   - animated: Should presentation be animated
    ///   - select: Selection callback
    ///   - deselect: Deselection callback
    ///   - cancel: Cancel callback
    ///   - finish: Finish callback
    ///   - completion: Presentation completion callback
    public func presentImagePicker(_ imagePicker: ImagePickerController, animated: Bool = true, select: ((_ asset: PHAsset) -> Void)?, deselect: ((_ asset: PHAsset) -> Void)?, cancel: (([PHAsset]) -> Void)?, finish: (([PHAsset]) -> Void)?, completion: (() -> Void)? = nil) {
        authorize {
            // Set closures
            imagePicker.onSelection = select
            imagePicker.onDeselection = deselect
            imagePicker.onCancel = cancel
            imagePicker.onFinish = finish

            // And since we are using the blocks api. Set ourselfs as delegate
            imagePicker.imagePickerDelegate = imagePicker

            // Present
            self.present(imagePicker, animated: animated, completion: completion)
        }
    }

    private func authorize(_ authorized: @escaping () -> Void) {
        if #available(iOS 14, *) {
            let accessLevel: PHAccessLevel = .readWrite
            PHPhotoLibrary.requestAuthorization(for: accessLevel) { [weak self] (status) in
                guard let self else { return }
                switch status {
                case .authorized:
                    DispatchQueue.main.async(execute: authorized)
                case .denied, .notDetermined, .restricted:
                    DispatchQueue.main.async {
                        self.presentAlert()
                    }
                case .limited:
                    DispatchQueue.main.async(execute: authorized)
                default:
                    break
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                guard let self else { return }
                switch status {
                case .authorized:
                    DispatchQueue.main.async(execute: authorized)
                case .denied, .notDetermined, .restricted:
                    self.presentAlert()
                case .limited:
                    DispatchQueue.main.async(execute: authorized)
                default:
                    break
                }
            }
        }
    }
    
    private func presentAlert() {
        let title = "allow_all_photos".localized()
        let message = "message_alert".localized()
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        let notNowAction = UIAlertAction(title: "not_now".localized(),
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(notNowAction)
        
        let openSettingsAction = UIAlertAction(title: "open_settings".localized(),
                                               style: .default) { [unowned self] (_) in
            // Open app privacy settings
            gotoAppPrivacySettings()
        }
        alert.addAction(openSettingsAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func gotoAppPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
                assertionFailure("Not able to open App privacy settings")
                return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension ImagePickerController {
    public static var currentAuthorization : PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
}

/// ImagePickerControllerDelegate closure wrapper
extension ImagePickerController: ImagePickerControllerDelegate {
    public func imagePicker(_ imagePicker: ImagePickerController, didSelectAsset asset: PHAsset) {
        onSelection?(asset)
    }

    public func imagePicker(_ imagePicker: ImagePickerController, didDeselectAsset asset: PHAsset) {
        onDeselection?(asset)
    }

    public func imagePicker(_ imagePicker: ImagePickerController, didFinishWithAssets assets: [PHAsset]) {
        onFinish?(assets)
    }

    public func imagePicker(_ imagePicker: ImagePickerController, didCancelWithAssets assets: [PHAsset]) {
        onCancel?(assets)
    }

    public func imagePicker(_ imagePicker: ImagePickerController, didReachSelectionLimit count: Int) {
        
    }
}
