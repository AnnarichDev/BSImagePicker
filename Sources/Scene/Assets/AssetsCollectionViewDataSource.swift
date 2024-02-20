// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
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

class AssetsCollectionViewDataSource : NSObject, UICollectionViewDataSource {
    private static let assetCellIdentifier = "AssetCell"
    private static let videoCellIdentifier = "VideoCell"
    private static let headerCellIdentifier = "HeaderCell"
    
    var settings: Settings!
    var fetchResult: PHFetchResult<PHAsset> {
        didSet {
            imageManager.stopCachingImagesForAllAssets()
        }
    }
    var imageSize: CGSize = .zero {
        didSet {
            imageManager.stopCachingImagesForAllAssets()
        }
    }

    var didManaged: (() -> Void)?
    private let imageManager = PHCachingImageManager()
    private let durationFormatter = DateComponentsFormatter()
    private let store: AssetStore
    private let contentMode: PHImageContentMode = .aspectFill

    init(fetchResult: PHFetchResult<PHAsset>, store: AssetStore) {
        self.fetchResult = fetchResult
        self.store = store
        durationFormatter.unitsStyle = .positional
        durationFormatter.zeroFormattingBehavior = [.pad]
        durationFormatter.allowedUnits = [.minute, .second]
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult[indexPath.row]
        let animationsWasEnabled = UIView.areAnimationsEnabled
        let cell: AssetCollectionViewCell
        
        UIView.setAnimationsEnabled(false)
        if asset.mediaType == .video {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetsCollectionViewDataSource.videoCellIdentifier, for: indexPath) as! VideoCollectionViewCell
            let videoCell = cell as! VideoCollectionViewCell
            videoCell.durationLabel.text = durationFormatter.string(from: asset.duration)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetsCollectionViewDataSource.assetCellIdentifier, for: indexPath) as! AssetCollectionViewCell
        }
        UIView.setAnimationsEnabled(animationsWasEnabled)

        cell.accessibilityIdentifier = "Photo \(indexPath.item + 1)"
        cell.accessibilityTraits = UIAccessibilityTraits.button
        cell.isAccessibilityElement = true
        cell.settings = settings
        
        loadImage(for: asset, in: cell)
        
        cell.selectionIndex = store.index(of: asset)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: AssetsCollectionViewDataSource.headerCellIdentifier, for: indexPath
            )
            
            headerCell.backgroundColor = .clear
            headerCell.clearAllSubviews()
            let mangeButton = UIButton()
            mangeButton.backgroundColor = .clear
            mangeButton.setTitleColor(.blue, for: .normal)
            mangeButton.setTitle("button_manage".localized(), for: .normal)
            mangeButton.layer.masksToBounds = true
            mangeButton.addTarget(self, action: #selector(didPrassedMange), for: .touchUpInside)
            mangeButton.translatesAutoresizingMaskIntoConstraints = false
            
            let messageLabel = UILabel()
            messageLabel.textColor = .black
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.text = "title_limited_media".localized()
            headerCell.addSubview(mangeButton)
            headerCell.addSubview(messageLabel)
            
            let views = ["mangeButton": mangeButton, "label": messageLabel]
            headerCell.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[label]-(<=1)-[mangeButton]-20-|", metrics: nil, views: views
                )
            )
            headerCell.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-10-[mangeButton(30)]-10-|", metrics: nil, views: views
                )
            )
            headerCell.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-10-[label(30)]-10-|", metrics: nil, views: views
                )
            )

            return headerCell
        } else {
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100.0)
    }
    
    static func registerCellIdentifiersForCollectionView(_ collectionView: UICollectionView?) {
        collectionView?.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: headerCellIdentifier
        )
        
        collectionView?.register(AssetCollectionViewCell.self, forCellWithReuseIdentifier: assetCellIdentifier)
        collectionView?.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: videoCellIdentifier)
    }
    
    private func loadImage(for asset: PHAsset, in cell: AssetCollectionViewCell) {
        // Cancel any pending image requests
        if cell.tag != 0 {
            imageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        // Request image
        cell.tag = Int(imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: contentMode, options: settings.fetch.preview.photoOptions) { (image, _) in
            guard let image = image else { return }
            cell.imageView.image = image
        })
    }
    
    @objc private func didPrassedMange() {
        didManaged?()
    }
}

extension AssetsCollectionViewDataSource: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let assets = indexPaths.map { fetchResult[$0.row] }
        imageManager.startCachingImages(for: assets, targetSize: imageSize, contentMode: contentMode, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {}
}
