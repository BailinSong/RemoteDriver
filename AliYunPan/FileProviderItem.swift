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
        self.fileInfo=fileInfo
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return identifier
    }
    
    var isTrashe:Bool{
        return fileInfo.trashed ?? false
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        var id:NSFileProviderItemIdentifier
        if fileInfo.parent_file_id == nil || fileInfo.parent_file_id == "" {
            id = NSFileProviderItemIdentifier.rootContainer
        }else if fileInfo.parent_file_id == "root" {
            id = NSFileProviderItemIdentifier.rootContainer
        }
        else if fileInfo.trashed ?? false {
            id = NSFileProviderItemIdentifier.trashContainer
        }
        else {
//            let parentFileId=String(data:try!JSONEncoder().encode(["did":fileInfo.drive_id,"fid":fileInfo.parent_file_id]),encoding: .utf8)
            id = NSFileProviderItemIdentifier(driveId: fileInfo.drive_id!, fileId: fileInfo.parent_file_id!)
        }
        AliSDK.printLog(message: id)
        return id
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        if contentType == .folder {
            return [.allowsReading, .allowsWriting, .allowsRenaming, .allowsReparenting, .allowsTrashing, .allowsDeleting]
        }else{
            return [.allowsReading, .allowsRenaming, .allowsReparenting, .allowsTrashing, .allowsDeleting]
        }
        
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: (fileInfo.content_hash?.data(using: .utf8)) ?? Data(), metadataVersion: fileInfo.crc64_hash?.data(using: .utf8) ?? Data())
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
        let formatter=DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: fileInfo.created_at ?? "")
    }
    
    var contentModificationDate: Date?{
        let formatter=DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: fileInfo.updated_at ?? "")
    }
    
    
}


extension NSFileProviderItemIdentifier{
    var driveId:String{
        String(rawValue.split(separator: ":")[0])
    }
    
    var fileId:String{
        String(rawValue.split(separator: ":")[1])
    }
  
    
    init(driveId:String,fileId:String){
        self.init(rawValue: driveId+":"+fileId)
    }
}


