//
//  ViewController.swift
//  Garage Opener
//
//  Created by Chachi Kruel on 7/23/15.
//  Copyright (c) 2015-2016 Chachi Kruel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var cameraWebView: UIWebView!
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    
    @IBAction func toggleTapped(_ sender: UIButton) {
        // The button was tapped, so let's make the REST POST call
        self.displayLabel.text = "Toggling garage door..."
        let(photonDeviceID, photonAccessToken, webcamEnable, webcamURL) = readSettings()
        toggleGarage(photonDeviceID, photonAccessToken, { (success) -> () in
            if (success == 0) {
                self.displayLabel.text = "Error toggling garage door"
                self.showWebcam(webcamEnable, webcamURL)
            }
        })

        // Find out if the garage door is open or closed
        isOpen(photonDeviceID, photonAccessToken, {
            (result: NSInteger) in
            if (result == 1) {
                self.displayLabel.text = "Garage door is open"
                self.showWebcam(webcamEnable, webcamURL)

            } else {
                self.displayLabel.text = "Garage door is closed"
                self.showWebcam(webcamEnable, webcamURL)
            }
        })
    }
    
    
    @IBAction func toggleCheck(_ sender: UIButton) {
        displayLabel.text = "Checking garage door..."
        // The Check Door button was tapped, so let's find out its status
        let(photonDeviceID, photonAccessToken, webcamEnable, webcamURL) = readSettings()
        isOpen(photonDeviceID, photonAccessToken, {
            (result: NSInteger) in
            print("result from toggleCheck: \(result)")
            if (result == 1) {
                self.displayLabel.text = "Garage door is open"
                self.showWebcam(webcamEnable, webcamURL)
            } else {
                self.displayLabel.text = "Garage door is closed"
                self.showWebcam(webcamEnable, webcamURL)
            }
        })
        showWebcam(webcamEnable, webcamURL)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        let appDelegate:AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.myViewController = self
        
        cameraWebView.delegate = self;
        //cameraWebView.hidden = true
        
        let(photonDeviceID, photonAccessToken, webcamEnable, webcamURL) = readSettings()

        // If no settings are defined, show the missing settings message
        if photonDeviceID.isEmpty == true {
            self.displayLabel.text = "Invalid Photon device ID"
        }
        else if photonAccessToken.isEmpty == true {
            self.displayLabel.text = "Invalid Photon access token"
        }
        else {
            // Find out if the garage door is open or closed
            self.displayLabel.text = "Checking garage door..."
            isOpen(photonDeviceID, photonAccessToken, {
                (result: NSInteger) in
                print("result from viewDidLoad: \(result)")
                if (result == 1) {
                    self.displayLabel.text = "Garage door is open"
                    self.showWebcam(webcamEnable, webcamURL)
                } else {
                    self.displayLabel.text = "Garage door is closed"
                    self.showWebcam(webcamEnable, webcamURL)
                }
            })
        }
    }

    
    func readSettings() -> (String, String, Bool, String) {
        // Read settings
        let userDefaults = UserDefaults.standard
        userDefaults.synchronize()
        var photonDeviceID: String = ""
        var photonAccessToken: String = ""
        var webcamEnable: Bool = false
        var webcamURL: String = ""
        if UserDefaults.standard.object(forKey: "photon_device_id") != nil {
            photonDeviceID = UserDefaults.standard.object(forKey: "photon_device_id") as! String
        }
        if UserDefaults.standard.object(forKey: "photon_access_token") != nil {
            photonAccessToken = UserDefaults.standard.object(forKey: "photon_access_token") as! String
        }
        if UserDefaults.standard.object(forKey: "webcam_enable") != nil {
            webcamEnable = UserDefaults.standard.object(forKey: "webcam_enable") as! Bool
        
        }
        if UserDefaults.standard.object(forKey: "webcam_url") != nil {
            webcamURL = UserDefaults.standard.object(forKey: "webcam_url") as! String
        }
        // print(photonDeviceID)
        // print(photonAccessToken)
        // print(webcamEnable)
        // print(webcamURL)
        return(photonDeviceID, photonAccessToken, webcamEnable, webcamURL)
    }
    

    func showWebcam(_ webcamEnable: Bool, _ webcamURL: String) {
        // Show the webcam if it's enabled and configured
        if (webcamEnable == true) {
            if webcamURL.isEmpty == true {
                let localfilePath = Bundle.main.url(forResource: "WebcamURLMissing", withExtension: "html");
                let myRequest = URLRequest(url: localfilePath!);
                cameraWebView.loadRequest(myRequest);
                self.view.addSubview(cameraWebView)
            }
            else {
                cameraWebView.isHidden = false
                loadGaragePhoto(webcamURL)
            }
        }
        else {
            let localfilePath = Bundle.main.url(forResource: "WebcamNotEnabled", withExtension: "html");
            let myRequest = URLRequest(url: localfilePath!);
            cameraWebView.loadRequest(myRequest);
            self.view.addSubview(cameraWebView)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        myActivityIndicator.startAnimating()
    }
    
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        myActivityIndicator.stopAnimating()
    }

    
    func loadGaragePhoto(_ cameraURL: String) {
        // Grab a live feed from the garage camera
        cameraWebView.scalesPageToFit = true
        let requestURL = URL(string:cameraURL)
        // print(requestURL)
        let request = URLRequest(url: requestURL!)
        cameraWebView.loadRequest(request)
    }
    
    func isOpen(_ deviceID: String, _ accessToken: String, _ completionHandler: @escaping (_ result: NSInteger) -> ()) {
        // Make a GET call to the Photon and get the value of variable isOpen
        
        // 1. Set up the URL request for GET
        let todoEndpoint: String = "https://api.particle.io/v1/devices/\(deviceID)/isopen?access_token=\(accessToken)"
        let url = URL(string: todoEndpoint)
        
        // 2. Make the GET request
        let task = URLSession.shared.dataTask(with: url! as URL) {
            data, response, error in
            // Do stuff with response, data & error here
            guard error == nil else {
                print("Error: unable to make GET request")
                print(error!)
                return
            }
            // Make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // Parse the result as JSON, since that's what the API provides
            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                    print("Error: Unable to convert data to JSON")
                    return
                }
                // now we have the todo, let's just print it to prove we can access it
                print("The response is:\n" + todo.description)
                
                // the todo object is a dictionary
                // so we just access the result using the "result" key
                // so check for a result and print it if we have one, then complete the function
                let result = todo["result"] as! NSInteger
                DispatchQueue.main.sync {
                    completionHandler(result)
                }
            } catch  {
                print("Error: failed trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    
    func toggleGarage(_ deviceID: String, _ accessToken: String, _ completionHandler: @escaping (_ result:NSInteger) -> ()) {
        // 1. Set up the URL request for POST
        let todoEndpoint: String = "https://api.particle.io/v1/devices/\(deviceID)/openclose"
        guard let url = URL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let postString = "access_token=\(accessToken)&args=Toggle+Garage+Door" // Key and Value
        urlRequest.httpBody = postString.data(using: .utf8)
        
        // 2. Make the POST request
        let task = URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            // Do stuff with response, data & error here
            guard error == nil else {
                print("Error: unable to make POST request")
                print(error!)
                return
            }
            // Make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // Parse the result as JSON, since that's what the API provides
            do {
                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                    print("Error: unable to convert response data to JSON")
                    return
                }
                // now we have the todo, let's just print it to prove we can access it
                print("The response is:\n" + todo.description)
                
                // the todo object is a dictionary
                // so we just access the result using the "result" key
                // so check for a result and print it if we have one, then complete the function
                let returnValue = todo["return_value"] as! NSInteger
                DispatchQueue.main.sync {
                    completionHandler(returnValue)
                }
            } catch  {
                print("Error: failure trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
}
