//
//  JXFileBrowserController.swift
//  JXFileBrowserController
//
//  Created by jiaxin on 2018/7/6.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

import UIKit

open class JXFileBrowserController: UIViewController {
    public let path: String!
    public var tableView: UITableView!
    public var dataSource: [String]!
    private let MainBundleResourcePath = "MainBundleResourcePath"
    private let EmptyTips = "There are no files here."

    init(path: String) {
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        if path == NSHomeDirectory() {
            self.title = "NSHomeDirectory"
        }else {
            self.title = URL(fileURLWithPath: path).lastPathComponent
        }

        dataSource = [String]()
        if path == NSHomeDirectory(), Bundle.main.resourcePath != nil {
            dataSource.append(MainBundleResourcePath)
        }
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: path)
            dataSource.append(contentsOf: fileNames)
        } catch let error {
            print("The error of contentsOfDirectory: %@", error)
        }
        if dataSource.isEmpty {
            dataSource.append(EmptyTips)
        }

        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }

    func isImagePathExtension(filePath: String) -> Bool {
        return ["jpg", "jpeg", "png", "gif", "tiff", "tif"].contains(URL(fileURLWithPath: filePath).pathExtension)
    }
}

extension JXFileBrowserController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }
        cell?.accessoryType = .disclosureIndicator
        cell?.detailTextLabel?.textColor = UIColor.lightGray
        let source = dataSource[indexPath.row]
        cell?.textLabel?.text = source
        if source == EmptyTips {
            cell?.detailTextLabel?.text = nil
        }
        var fullPath = path + "/" + source
        if source == MainBundleResourcePath {
            fullPath = Bundle.main.resourcePath!
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            if attributes[FileAttributeKey.type] as! String == FileAttributeType.typeDirectory.rawValue {
                let count = (try? FileManager.default.contentsOfDirectory(atPath: fullPath).count) ?? 0
                cell?.detailTextLabel?.text = String(format: "%d file%@", count, ((count > 1) ? "s" : ""))
            }else {
                let fileSize = attributes[FileAttributeKey.size] as! Double
                let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: ByteCountFormatter.CountStyle.file)
                cell?.detailTextLabel?.text = fileSizeString

                if isImagePathExtension(filePath: fullPath) {
                    cell?.imageView?.contentMode = .scaleAspectFit
                    cell?.imageView?.clipsToBounds = true
                    cell?.imageView?.image = UIImage(contentsOfFile: fullPath)
                }else {
                    cell?.imageView?.image = nil
                }
            }
        } catch let error {
            print("The error of attributesOfItem: %@", error)
        }
        return cell!
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let source = dataSource[indexPath.row]
        if source == EmptyTips {
            return
        }
        var fullPath = path + "/" + source
        if source == MainBundleResourcePath {
            fullPath = Bundle.main.resourcePath!
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            if attributes[FileAttributeKey.type] as? String == FileAttributeType.typeDirectory.rawValue {
                let fileBrowserController = JXFileBrowserController(path: fullPath)
                self.navigationController?.pushViewController(fileBrowserController, animated: true)
            }else {
                let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                sheet.addAction(UIAlertAction(title: "Preview", style: .default, handler: { (action) in
                    let previewVC = JXFilePreviewViewController(filePath: fullPath)
                    self.navigationController?.pushViewController(previewVC, animated: true)
                }))
                sheet.addAction(UIAlertAction(title: "Share", style: .default, handler: { (action) in
                    let activityController = UIActivityViewController(activityItems: [URL(fileURLWithPath: fullPath)], applicationActivities: nil)
                    self.present(activityController, animated: true, completion: nil)
                }))
                sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(sheet, animated: true, completion: nil)
            }
        } catch let error {
            let alert = UIAlertController(title: "The error of 'FileManager.default.attributesOfItem'", message: error.localizedDescription, preferredStyle: .alert)
            let confirm = UIAlertAction(title: "I know", style: .cancel, handler: nil)
            alert.addAction(confirm)
            self.present(alert, animated: true, completion: nil)
            print("The error of attributesOfItem: %@", error)
        }
    }
}
