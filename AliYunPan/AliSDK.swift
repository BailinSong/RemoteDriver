//
//  AliSDK.swift
//  Ali
//
//  Created by 宋柏霖 on 2022/6/29.
//

import Foundation
import Alamofire

@available(macOS 12.0, *)
public class AliSDK{
    
    public static func printLog<T>(message: T,
                                   file: String = #file,
                                   method: String = #function,
                                   line: Int = #line)
    {
        #if DEBUG
        print(Date().ISO8601Format()+"\t:\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
        #endif
    }
    
//    static let userData=UserDefaults.standard
    static let userData=try! UserDefaults.init(suiteName: "group.ooo.reindeer.RemoteDriver")!
    
    
    public static func getLoginQrCodeResult()->GeneratorQrCodeResult?{
        let decoder=JSONDecoder()
        
        let urlString: String = "https://passport.aliyundrive.com/newlogin/qrcode/generate.do?appName=aliyun_drive&isMobile=true"

        let response=AF.request(urlString)
        
        var  qrCodeResult:GeneratorQrCodeResult?
        
        
        let semaphore = DispatchSemaphore(value: 0)
        response.responseString{ afData in
            let str=try?afData.result.get()
            
            let result = try? decoder.decode(GeneratorQrCodeResult.self, from: (str?.data(using: .utf8))!!)
            qrCodeResult=result
           
            semaphore.signal()
        }
        
        semaphore.wait()
    
        return qrCodeResult
        
    }
    
    public static func getLoginResult(qrCodeResult:GeneratorQrCodeResult)->LoginResult?{
 
        let decoder=JSONDecoder()
        
        var logined=false
        
        var loginResult:LoginResult?
        
        var  qrFrom = QueryQrCodeCKForm()
        qrFrom.t=String(qrCodeResult.content?.data?.t ?? Int64(0))
//        qrFrom.t=qrCodeResult.content?.data?.t
        qrFrom.codeContent=qrCodeResult.content?.data?.codeContent ?? ""
        qrFrom.ck=qrCodeResult.content?.data?.ck ?? ""
        
//        var newheaders=HTTPHeaders()
//        newheaders.add(name: "content-type", value: "application/json;charset-utf-8")
        
        while(!logined){
          
            
            AF.request("https://passport.aliyundrive.com/newlogin/qrcode/query.do?appName=aliyun_drive&fromSite=52&_bx-v=2.0.31", method: .post, parameters: ["t":qrFrom.t,"ck":qrFrom.ck]).responseString { afData in
                let str=try?afData.result.get()
                print("getloginResultJson:",str)
                let result = try! decoder.decode(QueryQrCodeResult.self, from: (str?.data(using: .utf8))!!)
                
                if(!(result.hasError ?? false && result.content.success ?? false )){
                    
                    print("getloginResult",result)
                    
                    if(result.content.data.qrCodeStatus == "CONFIRMED"){
                        
                        if let json=result.content.data.bizExt!.decodeBase64(using: .init(rawValue: 0)){
                            print("json:"+json)
                            if let loginData = try? decoder.decode(LoginResult.self, from: json.data(using: .utf8, allowLossyConversion: true) ?? Data()){
                            
                                logined=true
                                loginResult=loginData
                                
                                
                               
                                let nowSecond=Int(Date().timeIntervalSince1970)+(loginResult?.pdsLoginResult.expiresIn ?? 1)
                                
                                userData.set(loginResult?.pdsLoginResult.refreshToken, forKey: "refreshToken")
                                userData.set(loginResult?.pdsLoginResult.accessToken, forKey: "accessToken")
                                userData.set(loginResult?.pdsLoginResult.tokenType, forKey: "tokenType")
                                userData.set(nowSecond, forKey: "expires")
                                userData.set("pJZInNHN2dZWk8qg", forKey: "appId")
                                
                                
                               
                            }
                        }
                    
                    }else if(result.content.data.qrCodeStatus == "EXPIRED"){
                        logined=true
                   
                    }
                    
                }
            
            }
            Thread.sleep(forTimeInterval: 1)
            
        }
        
        return loginResult
    }
    
    public static func needReLogin()->Bool{
        if let refreshToken=userData.string(forKey: "refreshToken"){
        
            return false
        }else{
            return true
        }
    }
    
  
    
    public static func _get<D: Decodable,E:Encodable>(url:String,parameters:E?,tokenType:String?,accessToken:String?,responseType:D.Type,headers:HTTPHeaders?)->D?{
        let decoder=JSONDecoder()
        
        var newheaders=HTTPHeaders()
        
        if(tokenType != nil && accessToken != nil){
            newheaders.add(name: "authorization", value: tokenType!+" "+accessToken!)
        }
        
        headers?.forEach{
            header in
            newheaders.add(name: header.name, value: header.value)
        }
        
        

        let response=AF.request(url, method: HTTPMethod.get, parameters: parameters, encoder: URLEncodedFormParameterEncoder(), headers: newheaders)
        
        var  returnResult:D?
        
        
        let semaphore = DispatchSemaphore(value: 0)
       
        response.responseString{ afData in
            let str=try?afData.result.get()
            
            let result = try? decoder.decode(responseType, from: (str?.data(using: .utf8))!!)
            returnResult=result
            semaphore.signal()
        }
        
        semaphore.wait()
    
        return returnResult
    }
    
    public static func _post<D: Decodable,E:Encodable>(url:String,parameters:E?,responseType:D.Type,headers:HTTPHeaders?)->D?{
        let decoder=JSONDecoder()
        
        var newheaders=HTTPHeaders()
        
//        newheaders.add(name: "authorization", value: """
//Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhN2U4OGYyMzBkOWU0OWM5YmU2YTI2MWU4OGEyZTFkZiIsImN1c3RvbUpzb24iOiJ7XCJjbGllbnRJZFwiOlwicEpaSW5OSE4yZFpXazhxZ1wiLFwiZG9tYWluSWRcIjpcImJqMjlcIixcInNjb3BlXCI6W1wiRFJJVkUuQUxMXCIsXCJGSUxFLkFMTFwiLFwiVklFVy5BTExcIixcIlNIQVJFLkFMTFwiLFwiU1RPUkFHRS5BTExcIixcIlNUT1JBR0VGSUxFLkxJU1RcIixcIlVTRVIuQUxMXCIsXCJCQVRDSFwiLFwiQUNDT1VOVC5BTExcIixcIklNQUdFLkFMTFwiLFwiSU5WSVRFLkFMTFwiXSxcInJvbGVcIjpcInVzZXJcIixcInJlZlwiOlwiXCIsXCJkZXZpY2VfaWRcIjpcIjI1MTQ4ZDU3NmYyOTQ4YjE4ZDA4MGUzNzMwYzNiMDI5XCJ9IiwiZXhwIjoxNjU3NTA1NDAwLCJpYXQiOjE2NTc0OTgxNDB9.Gk4PQsJXJy-u9KILakza4OLGAzPJOzEjgct8mcwxwPGZ1KXdKxod5WX5fFB5WrIrrWWD4c4rc-V9lEEbA21qLVCyaWUlNt9GlcDIZH4_TIHbid_ZjfAsMLRsQToUm7k3SMDTPNeWx4CI4_NcqxO0NNtqS3hFIOj6uEzoceWwS90
//""")
        
        if(userData.value(forKey: "tokenType") != nil && userData.value(forKey: "accessToken") != nil){
            newheaders.add(name: "authorization", value: (userData.value(forKey: "tokenType") as! String) + " " + (userData.value(forKey: "accessToken") as! String))
        }
        
        
        
        
        
        
        headers?.forEach{
            header in
            newheaders.add(name: header.name, value: header.value)
        }
        
        
        
        newheaders.add(name: "content-type", value: "application/json;charset-utf-8")

        printLog(message: newheaders)
        
        let response=AF.request(url, method: HTTPMethod.post, parameters: parameters, encoder: JSONParameterEncoder(), headers: newheaders)
        
        var  returnResult:D?
        
        
        let semaphore = DispatchSemaphore(value: 0)
       
        response.responseString{ afData in
            let str=try!afData.result.get()
            
            
            do {

                let result = try! decoder.decode(responseType, from: (str.data(using: .utf8))!)
                returnResult=result

            } catch {
                printLog(message: str)
            }
            
            
            semaphore.signal()
        }
        
        semaphore.wait()
    
        return returnResult
    }
    
}

public struct GeneratorQrCodeResult :Codable{
    var content:Content?
    var hasError:Bool?

}

extension GeneratorQrCodeResult{
    public struct Content:Codable{
        var data:Data?
        var status:Int?
        var success:Bool?
    }
}

extension GeneratorQrCodeResult.Content{
    public struct Data:Codable{
        var t:Int64?
        var codeContent:String?
        var ck:String?
        var resultCode:Int?
        var titleMsg:String?
        var traceId:String?
        var errorCode:String?
        var isMobile:Bool?
    }
}


public struct QueryQrCodeResult :Codable{
    var content:Content = Content()
    var hasError:Bool?
    
    
}
extension QueryQrCodeResult{
    public struct Content :Codable{
        var data:Data = Data()
        var status:Int?
        var success:Bool?
    }
}
extension QueryQrCodeResult.Content{
    public struct Data:Codable{
        var loginResult:String?
        var loginSucResultAction:String?
        var st:String?
        var qrCodeStatus:String?
        var loginType:String?
        var bizExt:String?
        var loginScene:String?
        var resultCode:Int?
        var appEntrance:String?
        var smartlock:Bool?
    }
}




public struct LoginResult:Codable{
    
    enum CodingKeys: String, CodingKey {
        // key 映射
        case pdsLoginResult = "pds_login_result"
    }
    
    public init(from decoder: Decoder) throws {
        // 自定义解码
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(LoginResult.PdsLoginResult.self, forKey: .pdsLoginResult) {
            self.pdsLoginResult = value
        } else {
            self.pdsLoginResult = try container.decode(LoginResult.PdsLoginResult.self, forKey: .pdsLoginResult)
        }
    }
    
    var pdsLoginResult:PdsLoginResult
    
    
}
extension LoginResult{
    public struct PdsLoginResult:Codable{
        var role:String?
//        var userData:UserData?
        var isFirstLogin:Bool?
        var needLink:Bool?
        var loginType:String?
        var nickName:String?
        var needRpVerify:Bool?
        var avatar:String?
        var accessToken:String?
        var userName:String?
        var userId:String?
        var defaultDriveId:String?
//        var existLink:[String]?
        var expiresIn:Int?
        var expireTime:String?
        var requestId:String?
        var dataPinSetup:Bool?
        var state:String?
        var tokenType:String?
        var dataPinSaved:Bool?
        var refreshToken:String?
        var status:String?
    }
}

extension LoginResult.PdsLoginResult{
    public struct UserData:Codable{
        var DingDingRobotUrl:String?
//        var EncourageDesc:String?
        var FeedBackSwitch:String?
        var FollowingDesc:String?
    //            var back_up_config:BackUpConfig = BackUpConfig()
        var ding_ding_robot_url:String?
//        var encourage_desc:String?
        var feed_back_switch:Bool?
        var following_desc:String?

    }
}

//        class BackUpConfig{
//            var ʖ뺱距:ʖ뺱距=ʖ뺱距()
//        }
//
//        class ʖ뺱距{
//            var folder_id:String = ""
//            var photo_folder_id:String = ""
//            var sub_folder:SubFolder = SubFolder()
//            var video_folder_id:String = ""
//
//        }
//        class SubFolder{}

public struct QueryQrCodeCKForm:Codable{
    var t:String = ""
    var codeContent:String = ""
    var ck:String = ""
    

}

extension String {
     //Base64编码
    public func encodBase64(using:String.Encoding) -> String? {
         if let data = self.data(using: using) {
             return data.base64EncodedString()
         }
         return nil
     }
 
     //Base64解码
    public func decodeBase64(using:String.Encoding) -> String? {
         if let data = Data(base64Encoded: self) {
             let json=String(data: data, encoding: using)
             return json
         }
         return nil
     }
}

/*
 
 刷新 token
 POST: https://auth.aliyundrive.com/v2/account/token

 { "grant_type": "refresh_token", "app_id": "pJZInNHN2dZWk8qg", "refresh_token": "c65bf6d104ac510885c0124d74c4a099" }

 
 {
   "default_sbox_drive_id": "9600002",
   "role": "user",
   "device_id": "2909000000004f01aa28264bfc30e4ed",
   "user_name": "151***111",
   "need_link": false,
   "expire_time": "2022-03-21T06:33:21Z",
   "pin_setup": true,
   "need_rp_verify": false,
   "avatar": "https://ccp-bj29-bj-1592982087.oss-cn-beijing.aliyuncs.com/2GhCur3G%2F...",
   "user_data": {
     "DingDingRobotUrl": "https://oapi.dingtalk.com/robot/send?access_token=0b4a936d0e...",
     "EncourageDesc": "内测期间有效反馈前10名用户将获得终身免费会员",
     "FeedBackSwitch": true,
     "FollowingDesc": "34848372",
     "back_up_config": {
       "手机备份": { "folder_id": "605c0c29b7acf78b6ee34bf095594f7654e57d68", "photo_folder_id": "605c0c299af37539f3d34879b2f0d1c5543f27d5", "sub_folder": {}, "video_folder_id": "605c0c29e520154c22644bed904b76b25ced317a" }
     },
     "ding_ding_robot_url": "https://oapi.dingtalk.com/robot/send?access_token=0b4a936d0e...",
     "encourage_desc": "内测期间有效反馈前10名用户将获得终身免费会员",
     "feed_back_switch": true,
     "following_desc": "34848372"
   },
   "token_type": "Bearer",
   "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..................",
   "default_drive_id": "9600002",
   "domain_id": "bj29",
   "refresh_token": "b2d9c244d8a24df38aa1a5dec59e2a92",
   "is_first_login": false,
   "user_id": "9400000000bc480bbcbbb1e074f55a7f",
   "nick_name": "myname",
   "exist_link": [],
   "state": "",
   "expires_in": 7200,
   "status": "enabled"
 }
 */


public struct AccountToken:Codable{
    var default_sbox_drive_id,role,device_id,user_name,expire_time,avatar,token_type,access_token,default_drive_id,domain_id,refresh_token,user_id,nick_name,state,status:String?
    var need_link,pin_setup,need_rp_verify,is_first_login:Bool?
    var expires_in:Int?
    var user_data:UserData?
    public struct UserData:Codable{
        var DingDingRobotUrl,EncourageDesc,FollowingDesc,ding_ding_robot_url,encourage_desc,following_desc:String?
        var FeedBackSwitch,feed_back_switch:Bool
        
    }

}

@available(macOS 12.0, *)
extension AliSDK{
public static func refreshToken()->AccountToken?{
    let response=_post(url: "https://auth.aliyundrive.com/v2/account/token", parameters: ["grant_type": "refresh_token", "app_id": userData.value(forKey: "appId") as! String, "refresh_token": userData.value(forKey: "refreshToken") as! String], responseType: AccountToken.self, headers: nil)
    printLog(message: response)
    if let accessToken=response?.access_token {
        let nowSecond=Int(Date().timeIntervalSince1970)+(response?.expires_in ?? 1)
        userData.set(nowSecond, forKey: "expires")
        userData.set(accessToken, forKey: "accessToken")
    }
    
    return response
    
}
}

/**
 获取默认网盘
  
 POST: https://api.aliyundrive.com/v2/drive/get_default_drive

 Response:

 {
   "domain_id": "bj29",
   "drive_id": "9600002",
   "drive_name": "Default",
   "description": "Created by system",
   "creator": "System",
   "owner": "ccff000000004d75b5788a481eed8386",
   "owner_type": "user",
   "drive_type": "normal",
   "status": "enabled",
   "used_size": 7186746146291,
   "total_size": 17536351469568,
   "store_id": "b5e90000000041d084733b520ea8b57d",
   "relative_path": "",
   "encrypt_mode": "none",
   "encrypt_data_access": false,
   "created_at": "2021-03-18T04:55:06.893Z",
   "permission": null,
   "subdomain_id": ""
 }
 {"domain_id":"bj29","drive_id":"28133360","drive_name":"Default","description":"Created by system","creator":"System","owner":"a7e88f230d9e49c9be6a261e88a2e1df","owner_type":"user","drive_type":"normal","status":"enabled","used_size":121656692313,"total_size":26910117593088,"store_id":"b5e9de389ef241d084733b520ea8b57d","relative_path":"","encrypt_mode":"none","encrypt_data_access":false,"created_at":"2021-03-23T10:04:19.572Z","permission":null,"subdomain_id":"","category":""}
 */
public struct Drive:Codable{
    var domain_id,drive_id,drive_name,description,creator,owner,owner_type,drive_type,status,store_id,relative_path,encrypt_mode,created_at,subdomain_id:String?
    var used_size,total_size:Int64?
    var encrypt_data_access:Bool?
}
@available(macOS 12.0, *)
extension AliSDK{
    public static func defaultDrive()->Drive?{
        let response=_post(url: "https://api.aliyundrive.com/v2/drive/get_default_drive",parameters: ["default":""], responseType: Drive.self, headers: nil)
        printLog(message: response)
        return response
        
    }
    
    public static func drive(driveId:String)->Drive?{
        let response=_post(url: "https://api.aliyundrive.com/v2/drive/get", parameters: [ "drive_id": driveId ], responseType: Drive.self, headers: nil)
        printLog(message: response)
        return response
        
    }
}

/**
 文件夹大小
 POST: https://api.aliyundrive.com/adrive/v1/file/get_folder_size_info

 { "drive_id": "9600002", "file_id": "623b00000000d89ef21d4118838aed83de7575ba" }
 Response:

 { "size": 67200, "folder_count": 0, "file_count": 600, "reach_limit": true }
 */
public struct FolderInfo:Codable{
    var reach_limit:Bool?
    var size,folder_count,file_count:Int64?
}
@available(macOS 12.0, *)
extension AliSDK{
    public static func folderInfo(driveId:String,fileId:String)->FolderInfo?{
        let response=_post(url: "https://api.aliyundrive.com/adrive/v1/file/get_folder_size_info", parameters: [ "drive_id": driveId, "file_id": fileId  ], responseType: FolderInfo.self, headers: nil)
        printLog(message: response)
        return response
        
    }
}

/**
 一个文件的信息
 POST: https://api.aliyundrive.com/v2/file/get

 {
   "drive_id": "9600002",
   "office_thumbnail_process": "image/resize,m_lfit,w_256,limit_0/format,jpg",
   "image_thumbnail_process": "image/resize,m_lfit,w_256,limit_0/format,jpg",
   "file_id": "623b00000000d89ef21d4118838aed83de7575ba",
   "video_thumbnail_process": "video/snapshot,t_0,f_jpg,m_lfit,w_256,ar_auto,m_fast",
   "permanently": false,
   "image_url_process": "image/resize,m_lfit,w_1080/format,webp",
   "url_expire_sec": 1800
 }
 Response:

 {
   "drive_id": "9600002",
   "domain_id": "bj29",
   "file_id": "623b00000000d89ef21d4118838aed83de7575ba",
   "name": "父文件夹23",
   "type": "folder",
   "created_at": "2021-11-05T12:23:02.914Z",
   "updated_at": "2022-01-24T10:53:36.469Z",
   "hidden": false,
   "starred": false,
   "status": "available",
   "user_meta": "{\"shares\":[\"2eVphedN4QT\"],\"client\":\"web\"}",
   "parent_file_id": "root",
   "encrypt_mode": "none",
   "creator_type": "User",
   "creator_id": "9400000000bc480bbcbbb1e074f55a7f",
   "last_modifier_type": "User",
   "last_modifier_id": "9400000000bc480bbcbbb1e074f55a7f",
   "revision_id": "",
   "ex_fields_info": { "image_count": 0 },
   "trashed": false
 }
 一个文件的信息 get_by_path
 POST: https://api.aliyundrive.com/v2/file/get_by_path

 { "drive_id": "9600002", "file_path": "/zip23" }
 Response:

 {
   "drive_id": "9600002",
   "domain_id": "bj29",
   "file_id": "623b00000000d89ef21d4118838aed83de7575ba",
   "name": "zip23",
   "type": "folder",
   "created_at": "2021-08-28T02:54:02.561Z",
   "updated_at": "2022-01-24T10:53:36.474Z",
   "hidden": false,
   "starred": false,
   "status": "available",
   "user_meta": "{\"shares\":[\"mUo000000ka\"]}",
   "parent_file_id": "root",
   "encrypt_mode": "none",
   "last_modifier_type": "User",
   "last_modifier_id": "9400000000bc480bbcbbb1e074f55a7f",
   "revision_id": "",
   "trashed": false
 }
 一个文件的路径（root[不含] -> file_id 本身）
 POST: https://api.aliyundrive.com/adrive/v1/file/get_path

 { "drive_id": "9600002", "file_id": "623b00000000d89ef21d4118838aed83de7575ba" }
 Response:

 {
   "items": [
     {
       "trashed": false,
       "created_at": "2021-11-06T02:51:06.833Z",
       "domain_id": "bj29",
       "drive_id": "9600002",
       "encrypt_mode": "none",
       "file_id": "623b00000000d89ef21d4118838aed83de7575ba",
       "hidden": false,
       "name": "donghua",
       "parent_file_id": "613800000000336ae9164455b135a9729a298c9c",
       "starred": false,
       "status": "available",
       "type": "folder",
       "updated_at": "2021-11-06T02:51:06.833Z",
       "user_meta": "{\"client\":\"web\"}",
       "ex_fields_info": { "image_count": 0 }
     },
     {
       "trashed": false,
       "created_at": "2021-11-05T12:23:02.914Z",
       "domain_id": "bj29",
       "drive_id": "9600002",
       "encrypt_mode": "none",
       "file_id": "623b00000000d89ef21d4118838aed83de7575ba",
       "hidden": false,
       "name": "父文件夹23",
       "parent_file_id": "root",
       "starred": false,
       "status": "available",
       "type": "folder",
       "updated_at": "2022-01-24T10:53:36.469Z",
       "user_meta": "{\"shares\":[\"mUo000000ka\"],\"client\":\"web\"}",
       "ex_fields_info": { "image_count": 0 }
     }
   ]
 }

 */
//public struct fileInfo:Codable{
//    var trashed,created_at,domain_id,drive_id,encrypt_mode,file_id,name,parent_file_id,status,type,updated_at,user_meta,revision_id:String?
//    var hidden,starred:Bool?
//}

public struct FileInfo:Codable{
    var drive_id,domain_id,file_id,name,type,content_type,created_at,updated_at,file_extension,mime_type,mime_extension,status,user_meta,upload_id,parent_file_id,crc64_hash,content_hash,content_hash_name,download_url,url,thumbnail,category,encrypt_mode,last_modifier_type,last_modifier_id,last_modifier_name,revision_id:String?

      var hidden,starred，trashed:Bool?


      var size,punish_flag:Int64?

      var labels:[String]?

    var image_media_metadata:ImageMediaMetadata?
    
    public struct ImageMediaMetadata:Codable{
        var width,height:Int?
        var exif:String?
        var image_quality:ImageQuality?
        
        public struct ImageQuality:Codable{
          var overall_score:Float?
        }
        
    }
    
}

public struct ListFiles:Codable{
    var items:[FileInfo]?
    var next_marker:String?
    var punished_file_count:Int?
}

public struct ListFileRequest:Codable{
    
    var drive_id,parent_file_id,marker:String
    var fields:String="*"
    var order_direction="DESC"
    var order_by="name"
    var limit=50
    var all=false
    var office_thumbnail_process="image/resize,m_lfit,w_256,limit_0/format,jpg"
    var image_thumbnail_process="image/resize,m_lfit,w_256,limit_0/format,jpg"
    var video_thumbnail_process="video/snapshot,t_0,f_jpg,m_lfit,w_256,ar_auto,m_fast"
    var image_url_process="image/resize,m_lfit,w_1080/format,webp"
    
}



@available(macOS 12.0, *)
extension AliSDK{
    public static func file(driveId:String,fileId:String)->FileInfo?{
        let response=_post(url: "https://api.aliyundrive.com/v2/file/get", parameters: [ "drive_id": driveId, "file_id": fileId  ], responseType: FileInfo.self, headers: nil)
        printLog(message: response)
        return response
        
    }
    
    public static func listfile(driveId:String,parentFileId:String,nextMarker:String)->ListFiles?{
        
        var request=ListFileRequest(drive_id: driveId, parent_file_id: parentFileId,marker:nextMarker)
        request.limit = 10
        
        let response=_post(url: "https://api.aliyundrive.com/v2/file/list", parameters: request, responseType: ListFiles.self, headers: nil)
        printLog(message: response)
        return response
        
    }
    
    
}
