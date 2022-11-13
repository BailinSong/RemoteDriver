//
//  FileProviderExtension.swift
//  AliYunPan
//
//  Created by 宋柏霖 on 2022/7/7.
//

import FileProvider


class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    
    var domain:NSFileProviderDomain
    
    
    
    required init(domain: NSFileProviderDomain) {
        // TODO: The containing application must create a domain using `NSFileProviderManager.add(_:, completionHandler:)`. The system will then launch the application extension process, call `FileProviderExtension.init(domain:)` to instantiate the extension for that domain, and call methods on the instance.
        self.domain=domain
        super.init()
       
        
    }
    
    func invalidate() {
        // TODO: cleanup any resources
    }
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        // resolve the given identifier to a record in the model
        AliSDK.printLog(message: "item")
        // TODO: implement the actual lookup
        
        if NSFileProviderItemIdentifier.rootContainer == identifier {
            AliSDK.printLog(message: identifier.rawValue)
            let drive = AliSDK.defaultDrive()
            let fileInfo = AliSDK.file(driveId: (drive?.drive_id!)!, fileId: "root")
            completionHandler(FileProviderItem(identifier: identifier,fileInfo: fileInfo!), nil)
        }else if NSFileProviderItemIdentifier.trashContainer == identifier {
            
            AliSDK.printLog(message: identifier.rawValue)
            let drive = AliSDK.defaultDrive()
            var fileInfo=FileInfo()
            fileInfo.name="废纸篓"
            fileInfo.drive_id=drive?.drive_id
            fileInfo.file_id="trash"
            fileInfo.parent_file_id=""
            fileInfo.type="folder"
            fileInfo.status="Available"
            completionHandler(FileProviderItem(identifier: .trashContainer,fileInfo: fileInfo), nil)
        }else if NSFileProviderItemIdentifier.workingSet == identifier{
            AliSDK.printLog(message: identifier.rawValue)
        } else{
            AliSDK.printLog(message: identifier.rawValue)
//            let itemId=try!JSONDecoder().decode([String:String].self, from: identifier.rawValue.data(using: .utf8)!)
            let fileInfo=AliSDK.file(driveId: identifier.driveId, fileId: identifier.fileId)
            
            if fileInfo?.file_id==nil{
                completionHandler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:]))
                
            }else {
                
                completionHandler(FileProviderItem(identifier: identifier,fileInfo: fileInfo!), nil)
            }
        }
        
        
        
        
        return Progress()
    }
    
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        // TODO: implement fetching of the contents for the itemIdentifier at the specified version
        AliSDK.printLog(message: "fetchContents")
        let progress=Progress()
        
        let fileInfo=AliSDK.file(driveId: itemIdentifier.driveId, fileId: itemIdentifier.fileId)
        _=try! AliSDK.download(driveId: itemIdentifier.driveId, fileId: itemIdentifier.fileId, progress: progress,completionHandler: { url, driveId,fileId, err in
            
            completionHandler(url, FileProviderItem(identifier: itemIdentifier,fileInfo: fileInfo!),nil)
        })
        
        
//        completionHandler(url, nil, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        
        return progress
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: a new item was created on disk, process the item's creation
        
        AliSDK.printLog(message: itemTemplate.contentType)
        
                
        var progress=Progress()
        
        AliSDK.create(
            fileName: itemTemplate.filename,
            parentFileId: itemTemplate.parentItemIdentifier == NSFileProviderItemIdentifier.rootContainer ? "root" : itemTemplate.parentItemIdentifier.fileId,
            type: url==nil ?"folder":"file",
            contentType: itemTemplate.contentType?.description,
            size: (itemTemplate.documentSize ?? nil) as? Int64,
            content: url,
            progress: progress) { fileInfo, error in
                completionHandler(FileProviderItem(identifier: .init(driveId: fileInfo.drive_id!, fileId: fileInfo.file_id!), fileInfo: fileInfo), [], false, nil)
            }
        
        
        return progress
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions =
    [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        AliSDK.printLog(message: "========================= modify item=============================")
        AliSDK.printLog(message: item)
        AliSDK.printLog(message: changedFields)
        AliSDK.printLog(message: options)
        AliSDK.printLog(message: request)
        var leftFields=changedFields
        
//       var fields = NSFileProviderItemFields()
        
        let  progress=Progress(totalUnitCount: 1)
        if(changedFields.contains(.contents)){
            
            AliSDK.printLog(message: "contents")
            leftFields.remove(.contents)
            if item.contentType == .folder{
                leftFields.remove(.contents)
               
                completionHandler(item,.contents,true,nil)
            }else{
              
                completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
            }
            
            
        }
        if(changedFields.contains(.parentItemIdentifier)){
            AliSDK.printLog(message: "parentItemIdentifier")
            
            leftFields.remove(.parentItemIdentifier)
            
            var remoteFile=AliSDK.file(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId)
            
            if item.parentItemIdentifier == .trashContainer {
                
                    AliSDK.trash(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId, progress: progress) { error in
                        
                        remoteFile?.trashed=true
                        completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: remoteFile!), leftFields, false, nil)
                    }
                
                
                return progress
            }else{
                
                if remoteFile?.trashed ?? false {
                    AliSDK.restore(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId, progress: progress) { error in
                        completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: remoteFile!), leftFields, false, nil)
                    }
                    return progress;
                }else if item.parentItemIdentifier == .rootContainer {
                    AliSDK.move(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId, parentFileId: "root", progress: progress) { error in
                        completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: remoteFile!), leftFields, false, nil)
                    }
                }else {
                
                    AliSDK.move(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId, parentFileId: item.parentItemIdentifier.fileId, progress: progress) { error in
                        
                        completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: remoteFile!), leftFields, false, nil)
                    }
                }
                    return progress
            }
//            }
//            completionHandler(item, [.parentItemIdentifier], true, nil)
        }
        
        
        var updateInfo = UpdateInfo()
        var needUpdate=false
        if(changedFields.contains(.filename)){
           
            AliSDK.printLog(message: "filename")
            leftFields.remove(.filename)
            updateInfo.name=item.filename
            needUpdate=true
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.contentModificationDate)){
            
            AliSDK.printLog(message: "contentModificationDate")
            leftFields.remove(.contentModificationDate)
            
            NSFileProviderManager(for: domain)?.signalEnumerator(for: item.itemIdentifier, completionHandler: { error in
                AliSDK.printLog(message: error)
            })
            
//            let df = DateFormatter()
//            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            updateInfo.local_modified_at=df.string(from: item.contentModificationDate!!)
//            completionHandler(item, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.creationDate)){
            AliSDK.printLog(message: "creationDate")
            leftFields.remove(.creationDate)
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.extendedAttributes)){
            AliSDK.printLog(message: "extendedAttributes")
            leftFields.remove(.extendedAttributes)
//            updateInfo.labels=item.extendedAttributes
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.favoriteRank)){
            AliSDK.printLog(message: "favoriteRank")
            leftFields.remove(.favoriteRank)
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.fileSystemFlags)){
            AliSDK.printLog(message: "fileSystemFlags")
            leftFields.remove(.fileSystemFlags)
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.lastUsedDate)){
            AliSDK.printLog(message: "lastUsedDate")
            leftFields.remove(.lastUsedDate)
            
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.tagData)){
            AliSDK.printLog(message: "tagData")
            leftFields.remove(.tagData)
//            updateInfo.labels = item.tagData
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        if(changedFields.contains(.typeAndCreator)){
            AliSDK.printLog(message: "typeAndCreator")
            leftFields.remove(.typeAndCreator)
//            completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        }
        
        if needUpdate {
        
            AliSDK.update(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId, info: updateInfo, progress: progress) { err in
                
                if err == nil {
                    AliSDK.fileAsync(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId) { fileInfo in
                        progress.completedUnitCount=1
                        completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: fileInfo), leftFields, true, nil)
                    }
                    
                }else{
                    completionHandler(nil, [], true, err)
                    AliSDK.printLog(message: err)
                }
                
            }
        }else{
            AliSDK.fileAsync(driveId: item.itemIdentifier.driveId, fileId: item.itemIdentifier.fileId) { fileInfo in
                progress.completedUnitCount=1
                completionHandler(FileProviderItem(identifier: item.itemIdentifier, fileInfo: fileInfo), leftFields, true, nil)
                
            }
        }
        
        AliSDK.printLog(message: "======================================================")
        
//        completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return progress
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        let progress=Progress(totalUnitCount: 1)
        AliSDK.deleteFile(driveId: identifier.driveId, fileId: identifier.fileId, progress: progress,completionHandler: completionHandler)
        
//        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        return FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
    }

}
