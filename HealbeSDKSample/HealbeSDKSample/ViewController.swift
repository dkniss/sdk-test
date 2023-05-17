//
//  ViewController.swift
//  HealbeSDKSample
//
//  Created by Alexander Kazansky on 05.08.2020.
//  Copyright © 2020 Alexander Kazansky. All rights reserved.
//

import UIKit

import HealbeSDK

struct Credentials {
    static let login = "my.login@email.com"
    static let password = "MyPassword"
    static let gobeName = "MyGobeName"
    static let pinCode = "010401" // my gobe pin
}

/// NOTE: this is only sample how to work with healbe sdk, so we use some code which is not  good for using in release application

class ViewController: UIViewController {
    
    @IBOutlet var sdkStatusLbl: UILabel!
    @IBOutlet var gobeStateLbl: UILabel!
    @IBOutlet var heartRateLbl: UILabel!
    @IBOutlet var stepsLbl: UILabel!
    
    var healbeSDKShared: HealbeSDKRoot!
    var gobeConnectInstance: GoBeConnectInterface!
    var gobeFunctionsInstance: GoBeFunction!
    var myGoBe: GoBeStruct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        healbeSDKShared = HealbeSDK.healbeSharedInstance
        
        if #available(iOS 13, *) {
            healbeSDKShared.awakeBluetooth() // Real users ask "why does app ask bluethooth permission right after start, but not when I access bluethooth first time" so we add this method and check have we permission to use bluetooth right now or not and if not - we call it not at application start, but when tap scan button in interface
        } else {
            // no action is needed on earlier versions
        }
        
        healbeSDKShared.sdkStatusObserver = { status in
            switch status {
            case .notInited, .undefined:
                print("Sdk is not ready for")
            case .needAuthorize:
                print("Sdk is not authorized. We need to login or signUp.")
                self.login()
            case .profileNeedFill:
                print("User profile is not fullfilled, we must to updateUser: data before continue working with this this user or signOut and login with another user")
            case .validNewUser:
                print("Sdk is ready to work. User hasn't connected to GoBe before")
                self.prepareBluetooth()
            case .validOldUser:
                print("Sdk is ready to work. User has connected GoBe before and sdk will try to connect to this GoBe")
                self.prepareBluetooth()
            case .networkConnectionRequired:
                print("Sdk needs network for continue working. There is only one case with this status right now (migration from previous healbe app version which was written without sdk), so you will not get this status in new project")
            }
            DispatchQueue.main.async {
                self.sdkStatusLbl.text = "\(status)"
            }
        }
    }
    
    func login() {
        healbeSDKShared.login(userName: Credentials.login,
                              password: Credentials.password) { result in
                                switch result {
                                case .success(_):
                                    print("We have successfully logged in")
                                case .failure(let error):
                                    // HealbeError is container for errors
                                    print("Something goes wrong - \(error.error)")
                                }
        }
    }
    
    func prepareBluetooth() {
        gobeConnectInstance = HealbeSDK.healbeSharedInstance
        gobeConnectInstance.gobeStateObserver = { state in
            DispatchQueue.main.async {
                self.gobeStateLbl.text = "\(state)"
            }
            switch state {
            case .ready:
                print("GoBe is connected to application and ready for working, updating current values and synchronization will star automaticaly")
                self.gobeConnectInstance.autoConnect = true
                self.startObservers()
            case .disconnected:
                print("GoBe is disconnected")
            case .needChangePin(_):
                print("GoBe is connected, but with default pincode and pincode needs to be changed before using. Pincode is changed by GoBeConnectInterface.changePincode ")
            case .requestPin(_):
                print("Both of entered to connect pib and defaul pin are not correct for current gobe, you should enter another pin via calling GoBeConnectInterface.connect")
            case .needCriticalUpdate:
                print("GoBe is connected, but it needs to be updated before been used. You should start updating Gobe via method GoBeFunction.updateFirmware")
            case .notRegisteredOnServer:
                print("This state means that something wrong with Gobe and we can't fix it automaticly. User should connect to our support")
            case .connected:
                print("This case means that BLE connection has been successfully established, but this is only one of the first stage of connection process which also contains authorizing, checking and updating some parameters on smartband, etc. No reaction are requered")
            default:
                print("All other values just show the current stage of the connection process and don't require reaction from app")
            }
        }
        if healbeSharedInstance.bluetoothIsOn {
            scanForGobe()
        }
    }
    
    func scanForGobe() {
        gobeConnectInstance.scan { (gobes, finished, error) in
            if let error = error {
                print("got error \(error)")
            }
            // we get new list of GoBe
            for gobe in gobes {
                print("name: \(gobe.name) | id: \(gobe.identifier)")
                if gobe.name == Credentials.gobeName {
                    // we found our gobe and can connect to it
                    self.connect(gobe)
                    break
                }
            }
            
            if finished {
                // the scan operation is over
                print("scan operation is finished")
            }
        }
    }
    
    func connect(_ gobe: GoBeStruct) {
        gobeConnectInstance.connect(gobe: gobe, pincode: Credentials.pinCode)
    }
    
    func startObservers() {
        let gobeFunctionsInstance = HealbeSDK.healbeSharedInstance
        gobeFunctionsInstance.heartRateObserver = { (heartRate, error) in
            var heartRateString = "unknown"
            if let error = error {
                print("got error instead heart rate, \(error.error)")
            } else {
                heartRateString = "\(heartRate)"
            }
            DispatchQueue.main.async {
                self.heartRateLbl.text = "\(heartRateString)"
            }
        }
        let timer = Timer(timeInterval: 5.0, repeats: true) { (_) in
            // we don't have any observers over activity right now so we do it via timer. Also this code is a snippet fo SDKDataProvider
            let dataProvider = self.healbeSDKShared.dataProvider
            let activitySummary = dataProvider.activitySummary(date: Date())
            var stepsString = "unknown"
            if let summary = activitySummary {
                stepsString = "\(summary.steps)"
            }
            DispatchQueue.main.async {
                self.stepsLbl.text = "\(stepsString)"
            }
        }
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
    }
}

