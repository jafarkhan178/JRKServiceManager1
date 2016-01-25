//
//  JRKServiceManager.swift
//  MetroLab
//
//  Created by Jafar on 28/10/15.
//  Copyright © 2015 sics. All rights reserved.
//

import UIKit
extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

class JRKServiceManager: NSObject,NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDelegate {
//http://sicsglobal.com/projects/App_projects/app_metrolabdc/api.php?request=login&type=patient&email=aswabm@gmail.com&password=asw123
    let mainUrl : String = "http://sicsglobal.com/projects/App_projects/app_metrolabdc/"
    var completionBlock:((Bool,AnyObject?,NSError?)->Void)?
    
    class func fetchdataFromService(serviceName : String?, parameter :[String:String]?, imageArray:[UIImage]?, completionHandler:(success : Bool, result:AnyObject?,error:NSError?)->Void)
    {
        let jrkserviceManager = JRKServiceManager()
        jrkserviceManager.completionBlock = completionHandler
        jrkserviceManager.loadRequestdataFromService(serviceName, parameter: parameter, imageArray: imageArray)
    }
    
    func loadRequestdataFromService(serviceName : String?, parameter :[String:String]? ,imageArray:[UIImage]?)
    {
        
        let boundary = generateBoundaryString()
        
        let request = NSMutableURLRequest(URL: NSURL(string: mainUrl  + serviceName!)!)
        var imageDataArray : [NSData] = [NSData]()
        if imageArray != nil
        {
            for (_,image) in (imageArray?.enumerate())!
            {
                imageDataArray.append(UIImageJPEGRepresentation(image, 0.5)!)
                
            }
            
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody = createBodyWithParameters(parameter, filePathKey: "picture", imageDataArray: imageDataArray, boundary: boundary)
        request.HTTPMethod = "POST"
        
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(title: "", message: "\(error!.localizedDescription)", delegate: nil, cancelButtonTitle: "Ok").show()
                })
                
            }
            let resultValue : AnyObject?
            do
            {
                resultValue = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                print(resultValue!.valueForKey("result")!)
                if  resultValue!.valueForKey("result")! as! NSObject  == true
                {
                    self.completionBlock!(true,resultValue,nil)
                    
                }
                else
                {
                    print(resultValue!.objectForKey("message")!)
                    self.completionBlock!(false,resultValue,nil)
                    
                }
            }
            catch let error as NSError {
                
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(title: "", message: "\(error.localizedDescription)", delegate: nil, cancelButtonTitle: "Ok").show()
                })
                
                
            }
            
        }
        task.resume()
        
        
        
        
        
    }
    
    /// Create request
    ///
    /// - parameter userid:   The userid to be passed to web service
    /// - parameter password: The password to be passed to web service
    /// - parameter email:    The email address to be passed to web service
    ///
    /// - returns:            The NSURLRequest that was created
    
//    func createRequestWithParameter(parameter :[String:String]) -> NSURLRequest {
//        let param = parameter  // build your dictionary however appropriate
//        
//        let boundary = generateBoundaryString()
//        
//        let url = NSURL(string: "https://example.com/imageupload.php")!
//        let request = NSMutableURLRequest(URL: url)
//        request.HTTPMethod = "POST"
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        let path1 = UIImageJPEGRepresentation(UIImage(named: "")!, 0.5)
//        request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", paths: path1, boundary: boundary)
//        
//        return request
//    }
    
    /// Create body of the multipart/form-data request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns:                The NSData of the body of the request
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataArray: [NSData]?, boundary: String) -> NSData {
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("\r\n--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)")

            }
        }
        
        if imageDataArray != nil {
            
            for (_,imageData) in (imageDataArray?.enumerate())!
            {
                body.appendString("\r\n--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(self.makeFileName())\"\r\n")
                body.appendString("Content-Type: application/octet-stream\r\n\r\n")
                body.appendData(imageData)
                body.appendString("\r\n--\(boundary)--\r\n")
  
            }
           
        }
        return body
    }
    
    func makeFileName()->String
    {
        let dateFormatter : NSDateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat =  "yyMMddHHmmssSSS"
        
        let dateString : NSString = dateFormatter.stringFromDate(NSDate())
        
        let randomValue : Int = Int(arc4random_uniform(3))
        let returnString : String = String(format: "\(dateString)\(randomValue).jpg")
        print(returnString)
        return returnString
    }
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
   
//    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
//        
//    }
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
//        
//    }
//    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
//        
//    }
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
//        
//    }
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//        
//    }
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
//        
//    }
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
//        
//    }
//    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
//        
//    }
//    
//    
//    //MARK:- NSURLSessionDataDelegate
//    
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
//        
//    }
//    @available(iOS 9.0, *)
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
//        
//    }
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
//        
//        
//    }
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
//        
//    }
//    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
//        
//    }
    
}
