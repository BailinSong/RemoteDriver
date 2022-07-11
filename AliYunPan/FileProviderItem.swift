//
//  FileProviderItem.swift
//  AliYunPan
//
//  Created by 宋柏霖 on 2022/7/7.
//

import FileProvider
import UniformTypeIdentifiers
import Alamofire





class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
    
    private let identifier: NSFileProviderItemIdentifier
    private let fileInfo:FileInfo
    
    
    init(identifier: NSFileProviderItemIdentifier,fileInfo:FileInfo) {
        self.identifier = identifier
        self.fileInfo=fileInfo;
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return identifier
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        var id:NSFileProviderItemIdentifier
        if fileInfo.parent_file_id == nil || fileInfo.parent_file_id == "" {
            id = NSFileProviderItemIdentifier("NSFileProviderRootContainerItemIdentifier")
        }else if fileInfo.parent_file_id == "root" {
            id = NSFileProviderItemIdentifier("NSFileProviderRootContainerItemIdentifier")
        }else{
            let parentFileId=String(data:try!JSONEncoder().encode(["did":fileInfo.drive_id,"fid":fileInfo.parent_file_id]),encoding: .utf8)
            id = NSFileProviderItemIdentifier(parentFileId!)
        }
        AliSDK.printLog(message: id)
        return id
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        return [.allowsReading, .allowsWriting, .allowsRenaming, .allowsReparenting, .allowsTrashing, .allowsDeleting]
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: fileInfo.crc64_hash?.data(using: .utf8)! ?? Data(), metadataVersion: try!JSONEncoder().encode(fileInfo))
    }
    
    var filename: String {
        return fileInfo.name ?? ""
    }
    
    var contentType: UTType {
        
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            return .folder
        }
        
        if fileInfo.type=="folder" {
            return .folder
        }else{
            return .init("."+(fileInfo.type ?? ".plainText")) ?? .plainText
        }
        
    }
    
    var documentSize: NSNumber?{
        return fileInfo.size as NSNumber?
    }
    
    var creationDate: Date?{
        var formatter=DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: fileInfo.created_at ?? "")
    }
    
    var contentModificationDate: Date?{
        var formatter=DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: fileInfo.updated_at ?? "")
    }
}
