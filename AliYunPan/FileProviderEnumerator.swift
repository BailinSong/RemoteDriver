//
//  FileProviderEnumerator.swift
//  AliYunPan
//
//  Created by 宋柏霖 on 2022/7/7.
//

import FileProvider



class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier
    private let anchor = NSFileProviderSyncAnchor("an anchor".data(using: .utf8)!)
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
        
        var fileProviderItems:[FileProviderItem]=[]
        
        var nextMarker:String=""
//        var nextMarker:String=String(data:page.rawValue,encoding:.utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n\t\0")) ?? ""
        
        
//        if(nextMarker=="FPPageSortedByName"){
//            nextMarker=""
//        }
        
        AliSDK.printLog(message: "nextMarker:"+nextMarker)
        switch enumeratedItemIdentifier {
        case NSFileProviderItemIdentifier.rootContainer :
            AliSDK.printLog(message: "rootContainer:"+enumeratedItemIdentifier.rawValue)
            repeat{
                if let files=AliSDK.listfile(driveId: (AliSDK.defaultDrive()?.drive_id)!, parentFileId: "root",nextMarker:nextMarker){
                    files.items?.forEach({ fileInfo in
                    
//                        let fileId=String(data:try!JSONEncoder().encode(["did":fileInfo.drive_id,"fid":fileInfo.file_id]),encoding: .utf8)
                        fileProviderItems.append(FileProviderItem(identifier: NSFileProviderItemIdentifier(driveId: fileInfo.drive_id!,fileId: fileInfo.file_id!),fileInfo: fileInfo))
                        
                    })
                    observer.didEnumerate(fileProviderItems)
                    fileProviderItems.removeAll()
                    nextMarker=files.next_marker ?? ""
                }
            }while nextMarker != ""
            
            break
        case NSFileProviderItemIdentifier.trashContainer :
            AliSDK.printLog(message: "trashContainer:"+enumeratedItemIdentifier.rawValue)
            break
        case NSFileProviderItemIdentifier.workingSet :
            AliSDK.printLog(message: "workingSet:"+enumeratedItemIdentifier.rawValue)
            break
        default:
            AliSDK.printLog(message: "default:"+enumeratedItemIdentifier.rawValue)
            
                repeat{
                    AliSDK.printLog(message: enumeratedItemIdentifier.rawValue)
                    
//                    let itemId=try!JSONDecoder().decode([String:String].self, from: enumeratedItemIdentifier.rawValue.data(using: .utf8)!)
                    if let files=AliSDK.listfile(driveId: enumeratedItemIdentifier.driveId, parentFileId: enumeratedItemIdentifier.fileId,nextMarker:nextMarker){
                        files.items?.forEach({ fileInfo in
//                            let fileId=String(data:try!JSONEncoder().encode(["did":fileInfo.drive_id,"fid":fileInfo.file_id]),encoding: .utf8)
                            
                            fileProviderItems.append(FileProviderItem(identifier: NSFileProviderItemIdentifier(driveId: fileInfo.drive_id!,fileId: fileInfo.file_id!),fileInfo: fileInfo))
                        })
                        nextMarker=files.next_marker ?? ""
                    }
                    observer.didEnumerate(fileProviderItems)
                    fileProviderItems.removeAll()
                }while nextMarker != ""
           
           
            
        }
        
        
        AliSDK.printLog(message: fileProviderItems)
//        AliSDK.refreshToken()
        
//        observer.didEnumerate([FileProviderItem(parentIdentifier: NSFileProviderItemIdentifier("root"), identifier: NSFileProviderItemIdentifier("a file1"))])
//        observer.didEnumerate([FileProviderItem(parentIdentifier: NSFileProviderItemIdentifier("root"), identifier: NSFileProviderItemIdentifier("a file2"))])
        if(nextMarker == ""){
            observer.finishEnumerating(upTo: nil)
        }else{
            observer.finishEnumerating(upTo: NSFileProviderPage(nextMarker.data(using: .utf8) ?? Data()))
        }
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
        observer.finishEnumeratingChanges(upTo: anchor, moreComing: false)
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(anchor)
    }
}
