//
//  FileProviderExtension.swift
//  AliYunPan
//
//  Created by 宋柏霖 on 2022/7/7.
//

import FileProvider


class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    required init(domain: NSFileProviderDomain) {
        // TODO: The containing application must create a domain using `NSFileProviderManager.add(_:, completionHandler:)`. The system will then launch the application extension process, call `FileProviderExtension.init(domain:)` to instantiate the extension for that domain, and call methods on the instance.
        super.init()
    }
    
    func invalidate() {
        // TODO: cleanup any resources
    }
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        // resolve the given identifier to a record in the model
        
        // TODO: implement the actual lookup
        
        if NSFileProviderItemIdentifier.rootContainer == identifier {
            AliSDK.printLog(message: identifier.rawValue)
            let drive = AliSDK.defaultDrive()
            let fileInfo=AliSDK.file(driveId: (drive?.drive_id!)!, fileId: "root")
            completionHandler(FileProviderItem(identifier: identifier,fileInfo: fileInfo!), nil)
        }else if NSFileProviderItemIdentifier.trashContainer == identifier {
            
            AliSDK.printLog(message: identifier.rawValue)
            let drive = AliSDK.defaultDrive()
            var fileInfo=FileInfo()
            fileInfo.name="废纸篓"
            fileInfo.drive_id=drive?.drive_id
            fileInfo.file_id="recyclebin"
            fileInfo.parent_file_id=""
            fileInfo.type="folder"
            fileInfo.status="Available"
            completionHandler(FileProviderItem(identifier: identifier,fileInfo: fileInfo), nil)
        }else if identifier.rawValue.starts(with: "{"){
            AliSDK.printLog(message: identifier.rawValue)
            let itemId=try!JSONDecoder().decode([String:String].self, from: identifier.rawValue.data(using: .utf8)!)
            let fileInfo=AliSDK.file(driveId: itemId["did"]!, fileId: itemId["fid"]!)
            completionHandler(FileProviderItem(identifier: identifier,fileInfo: fileInfo!), nil)
        }else{
            AliSDK.printLog(message: identifier.rawValue)
        }
        
        
        
        
        return Progress()
    }
    
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        // TODO: implement fetching of the contents for the itemIdentifier at the specified version
        
        completionHandler(nil, nil, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: a new item was created on disk, process the item's creation
        
        completionHandler(itemTemplate, [], false, nil)
        return Progress()
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        
        completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        
        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        return FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
    }
}
