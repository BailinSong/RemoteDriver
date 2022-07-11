//
//  ContentView.swift
//  RemoteDriver
//
//  Created by 宋柏霖 on 2022/7/6.
//

import SwiftUI
import CoreData
import CoreImage.CIFilterBuiltins
import FileProvider


struct ContentView: View {
    @State private var image: NSImage=NSImage(size: NSSize(width: 256, height: 256))
 
    var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation( .none)
                    .frame(width: 256, height: 256)
            }
        }
        .onAppear {
            
//            if UserDefaults.standard.string(forKey: "refreshToken") == nil{
            Thread{
            if AliSDK.needReLogin() {
               
                
                    var logined=false

                    while(!logined){
                        if let loginQrContent=AliSDK.getLoginQrCodeResult(){

                            if let codeContent=loginQrContent.content?.data?.codeContent{
                                generateImage(qrcode: codeContent)
                                
                                if AliSDK.getLoginResult(qrCodeResult: loginQrContent) != nil{
                                    logined=true
                                    
                                    
                                }

                            }

                        }
                        
                    }
                    
                    
                    
//                    let domain=NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: "Aliyunpan") ,displayName: "阿里云盘")
//
//                    NSFileProviderManager.remove(domain) { error in
//                        if let err=error {
//                            print(err)
//                        }else{
//                            print("阿里云盘卸载完成")
//                        }
//                    }
//
//                    NSFileProviderManager.add(domain) { error in
//                        if let err=error {
//                            print(err)
//                        }else{
//                            print("阿里云盘挂载完成")
//                        }
//
//                    }
                
            
//            }
            }else{
                let domain=NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: "Aliyunpan") ,displayName: "阿里云盘")
                AliSDK.printLog(message: "不需要重新登录")
                AliSDK.refreshToken()
                NSFileProviderManager.remove(domain) { error in
                    if let err=error {
                        print(err)
                    }else{
                        print("阿里云盘卸载完成")
                    }
                }

                NSFileProviderManager.add(domain) { error in
                    if let err=error {
                        print(err)
                    }else{
                        print("阿里云盘挂载完成")
                    }

                }
                
            }
            }.start()
                
        }
           
        
    }
    

 
    private func generateImage(qrcode:String) {
 
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        print("qrcode:"+qrcode)
 
        
        filter.message = Data(qrcode.utf8)

        guard
            let outputImage = filter.outputImage,
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else { return }

        self.image = NSImage(cgImage: cgImage, size: NSSize(width: 256, height: 256))
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
