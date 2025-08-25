//
//  HttpClientApi.swift
//
//  Created by Evan Snyder on 7/17/18.
//

import Foundation

//HTTP Methods
public enum HttpMethod : String, Sendable {
    case  GET
    case  POST
    case  DELETE
    case  PUT
    case  PATCH
}
typealias ServerTokenInfo = (audience: String, tokenDefault: String, token: String?)
private let fileName = "HttpClientApi.swift"


open class HttpClientApi: NSObject, @unchecked Sendable{
    //TODO: remove app transport security arbitary constant from info.plist file once we get API"s
    var request : URLRequest?
    var session : URLSession?
    
    let tokenPayload = [
        "client_id": "ios",
        "client_secret": "293bfbf06b93e943b32341e359fe695ef3e245d8e5d5bb9ee852ba08b5aef64a",
        "grant_type": "client_credentials"
    ]
    
    public static func instance() ->  HttpClientApi{
        
        return HttpClientApi()
    }
    
    func getToken(serverInfo: ServerTokenInfo, success: @escaping @Sendable (Data?, HTTPURLResponse?, Error?) -> Void, failure: @escaping @Sendable (Data?, HTTPURLResponse?, Error? ) -> Void) {
        
        var postData = tokenPayload
        if let tokenDealerSecret = KeyValueStore.getString(key: KeyValueStore.orgTokenDealerSecret) {
            postData["client_secret"] = tokenDealerSecret
            print("tokenDealerSecret: " + tokenDealerSecret)
        }
        postData["audience"] = serverInfo.audience
        print("tokenDealr params: \(String(describing: postData))")
      //  print("Firebase registration token: \(String(describing: fcmToken))")
        let postDataParams = Params(paramsData: postData)
        makeAPICall(url: Constants.Tokendealer.url + Constants.Tokendealer.Endpoints.createToken, params: postDataParams, method: HttpMethod.POST, success: { (data, response, error) in
            let responseJson = try? JSONSerialization.jsonObject(with: data!) as? NSDictionary
            KeyValueStore.putString(key: serverInfo.tokenDefault, value: responseJson![Constants.Tokendealer.PostData.accessToken] as? String)
   //         print("in the keyStore, tokenDefault is : " + KeyValueStore.getString(key: serverInfo.tokenDefault))
            success(data, response, error)
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "getToken")
            failure(data, response, error)
        }, canBeReauthorized: false)
    }
    
    func makeAPICall(url: String, params: Params?,
                     method: HttpMethod,
                     success: @escaping @Sendable ( Data?, HTTPURLResponse?, Error? ) -> Void,
                     failure: @escaping @Sendable ( Data?, HTTPURLResponse?, Error? ) -> Void,
                     canBeReauthorized: Bool = true,
                     isRetry: Bool = false) {
        print("makeAPICall for url: " + url)
        request = URLRequest(url: URL(string: url)!)
        let serverInfo = getAudienceFromUrl(url: url)
        
        let paramsPayload = params?.paramsData
        
        
        if serverInfo.token != nil {
            request?.setValue(KeyValueStore.bearer + " " + serverInfo.token!, forHTTPHeaderField: KeyValueStore.authorizationHeader)
        }
        request?.setValue(KeyValueStore.nudgeLibraryVersion,forHTTPHeaderField: KeyValueStore.nudgeLibraryVersionHeader)
        if let params = paramsPayload {
            let  jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request?.setValue(KeyValueStore.applicationJson, forHTTPHeaderField: KeyValueStore.contentType)
            request?.httpBody = jsonData//?.base64EncodedData()
            //paramString.data(using: String.Encoding.utf8)
        }
        request?.httpMethod = method.rawValue
        
        
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        
        session = URLSession(configuration: configuration)
        
        session?.dataTask(with: request! as URLRequest) { (data, response, error) -> Void in
            
            if let data = data {
                
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    success(data, response, error as NSError?)
                } 
                else if let response = response as? HTTPURLResponse, (response.statusCode == 401 || response.statusCode == 403) {
                    if canBeReauthorized {
                        self.getToken(serverInfo:serverInfo, success: { (data, response, error) in
                            if !isRetry {
//                                DispatchQueue.global().async {
                                    self.makeAPICall(url: url, params: params, method: method, success: success, failure: failure, canBeReauthorized: true, isRetry: true)
                                    
//                                }
                            }
                        }, failure: { (data, response, error) in
//                            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "makeAPICall")
                            KeyValueStore.putBoolean(key: KeyValueStore.isAuthenticated, value: false)
                        })
                    }
                } 
                else {
                    failure(data , response as? HTTPURLResponse, error as NSError?)
                }
            }else {
                failure(data , response as? HTTPURLResponse, error as NSError?)
            }
            }.resume()
    }
    
    private func getAudienceFromUrl(url: String) -> ServerTokenInfo {
        if url.contains(Constants.Core.url) {
            return (
                audience: Constants.Tokendealer.PostData.coreAudience,
                tokenDefault: KeyValueStore.coreServerToken,
                token:   KeyValueStore.getString(key: KeyValueStore.coreServerToken)
            )
        } else {
            return (
                audience: "",
                tokenDefault: "",
                token: nil
            )
        }
    }
}


extension HTTPURLResponse: @unchecked Sendable {}

extension NSError: @unchecked Sendable {}
