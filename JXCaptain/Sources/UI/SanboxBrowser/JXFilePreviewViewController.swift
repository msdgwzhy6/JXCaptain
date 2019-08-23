//
//  JXFilePreviewViewController.swift
//  JXCaptain
//
//  Created by jiaxin on 2019/8/23.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import UIKit

class JXFilePreviewViewController: UIViewController, UIScrollViewDelegate {
    let filePath: String
    var previewImageView: UIImageView?
    var previewScrollView: UIScrollView?
    var previewTextView: UITextView?

    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "File Preview"
        view.backgroundColor = .white

        let fileExtension = URL(fileURLWithPath: filePath).pathExtension
        if ["png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "gif", "GIF"].contains(fileExtension) {
            let image = UIImage(contentsOfFile: filePath)
            previewScrollView = UIScrollView()
            previewScrollView?.delegate = self
            previewScrollView?.minimumZoomScale = 1
            var imageWidthScale: CGFloat = 1
            if view.bounds.size.width > 0 {
                imageWidthScale = (image?.size.width ?? 0)/view.bounds.size.width
            }
            previewScrollView?.maximumZoomScale = max(2, imageWidthScale)
            view.addSubview(previewScrollView!)

            previewImageView = UIImageView(image: image)
            previewImageView?.contentMode = .scaleAspectFit
            previewScrollView?.addSubview(previewImageView!)
        }else if ["strings", "plist", "txt", "log", "csv"].contains(fileExtension) {
            if ["strings", "plist"].contains(fileExtension) {
                if let data = FileManager.default.contents(atPath: filePath), let keyValues = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String] {
                    let text = keyValues.reduce("") { (result, item) -> String in
                        return "\(result)\n\(item)"
                    }
                    initTextView(with: text)
                }else {
                    initTextView(with: "该文件没有内容")
                }
            }else {
                if let data = FileManager.default.contents(atPath: filePath), let text = String.init(data: data, encoding: .utf8) {
                    initTextView(with: text)
                }else {
                    initTextView(with: "该文件没有内容")
                }
            }
        }else {
            initTextView(with: "不支持该文件类型\(URL(fileURLWithPath: filePath).pathExtension)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        previewTextView?.frame = view.bounds
        previewScrollView?.frame = view.bounds
        previewScrollView?.contentSize = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
        let imageWidth = previewImageView?.image?.size.width ?? 0
        let imageHeight = previewImageView?.image?.size.width ?? 0
        let imageViewWidth = min(imageWidth, view.bounds.size.width)
        let imageViewHeight = min(imageHeight, view.bounds.size.height)
        previewImageView?.bounds = CGRect(x: 0, y: 0, width: imageViewWidth, height: imageViewHeight)
        previewImageView?.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
    }

    func initTextView(with text: String) {
        previewTextView = UITextView()
        previewTextView?.isEditable = false
        previewTextView?.font = .systemFont(ofSize: 12)
        previewTextView?.textColor = .black
        previewTextView?.backgroundColor = .white
        previewTextView?.isScrollEnabled = true
        previewTextView?.textAlignment = .left
        previewTextView?.text = text
        view.addSubview(previewTextView!)
    }

    //MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return previewImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        if scrollView.contentSize.width > view.bounds.size.width {
            center.x = scrollView.contentSize.width/2
        }
        if scrollView.contentSize.height > view.bounds.size.height {
            center.y = scrollView.contentSize.height/2
        }
        previewImageView?.center = center
    }
}
