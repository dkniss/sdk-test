# Healbe SDK Usage Example
Healbe SDK lets you work with GoBe smart devices. It is fully compatible with both GoBe2 & GoBe3 hardware. Healbe SDK doesn't contain any external dependencies.

## Requirements

* Xcode 13.4
* Swift 5.2

## Installation

There are two ways to use HealbeSDK: Manual Embed or via CocoaPods

### Manual Embed

1. Download `HealbeSDK` binary from this repo (https://bitbucket.org/Healbe/healbe-public-ios-sdk.git)
1. Open your project in Xcode
1. Add `HealbeSDK.framework` to project via **File** > **Add Files to MyProject**
1. Set `HealbeSDK` embedding to **"Embed and Sign"** in your project target settings, tab **General**, section **Frameworks, Libraries, and Embedded Content**
1. In your project target settings at **Build Phases** tab add the build phase **"Run script phase"** after **"Embed Frameworks"** phase with the following script\*:

```bash

# based on cocoapods strip_invalid_archs()
binary="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/HealbeSDK.framework/HealbeSDK"

# Get architectures for current target binary
binary_archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | awk '{$1=$1;print}' | rev)"
stripped=""
for arch in $binary_archs; do
   if ! [[ "${ARCHS}" == *"$arch"* ]]; then
     # Strip non-valid architectures in-place
     lipo -remove "$arch" -output "$binary" "$binary"
     stripped="$stripped $arch"
   fi
 done
 if [[ "$stripped" ]]; then
   echo "Stripped $binary of architectures:$stripped"
 fi

```
\* This script will strip simulator architectures

### Using [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!
source 'https://bitbucket.org/Healbe/healbe-public-ios-sdk.git'

target 'YOUR_TARGET_NAME' do
pod 'HealbeSDK'
end

```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### Using Swift Package Manager

Swift Package Manager

```swift
dependencies: [
    .package(url: "https://bitbucket.org/Healbe/healbe-public-ios-sdk.git", branch: "master")
]
```

### Configuring your app

You should set **NSBluetoothAlwaysUsageDescription** and **NSBluetoothPeripheralUsageDescription** in your app's `Info.plist` for using BLE. Also, you can turn on using Bluetooth in background modes into **Signing & Capabilities** tab.

## Documentation

Full documentation is available at https://drive.google.com/drive/folders/1HHoLLhQ1CN-NYRPKCBXDa4TaQ-4lUHOr


## Quickstart

### Initialization

First of all, you need to import HealbeSDK Framework

```swift
  import HealbeSDK
```
SDK entry point is **HealbeSDK.healbeSharedInstance** which implements **HealbeSDKRoot** protocol. Property **sdkStatus** describes current SDK status and this status defines what your app needs or can do at the moment. You can subscribe to its changing.

SDK methods mostly check the status when you called them so SDK will not crash or make some wrong actions if you call some method in a wrong state.

```swift
        let   healbeSharedInstance: HealbeSDKRoot = HealbeSDK.healbeSharedInstance
        
        // subscribe to sdkStatus changing
        healbeSharedInstance.sdkStatusObserver = { status in
            switch status {
            case .notInited, .undefined:
              print("Sdk is not ready for")
            case .needAuthorize:
             print("Sdk is not authorized. We need to login or signUp.")
            case .profileNeedFill:
              print("User profile is not fulfilled, we must fill it using updateUser: data before continue working with this user")
            case .validNewUser:
              print("Sdk is ready to work. User hasn't connected to GoBe before")
            case .validOldUser:
              print("Sdk is ready to work. User has connected GoBe before and sdk will try to connect to this GoBe")
            case .networkConnectionRequired:
              print("Sdk needs network for continue working. This is possible only when SDK is trying to migrate data from old HEALBE app version 1.6.5 or earlier.)
            }
        }
        
        // Also you can read which status sdk has right now.
        let status = healbeSharedInstance.sdkStatus
        // do something with status
```

SDK initializes when you use **healbeSharedInstance** first time. It needs some time to init all internal entries, so it is not a good idea to use **healbeSharedInstance.sdkStatus** the first appeal to **healbeSharedInstance**.

### Authentification

Healbe SDK requires authentification to protect GoBe’s algorithms and user’s data. If SDK status is **.needAuthorize** you need an authorized user to work further — so log in or sign up. Healbe SDK will authorize and remember the user, and next time it will authenticate automatically during setup process. Login and Signup methods requires you to pass login and password.

After logging in or signing up a User object will become available and you will be able to link HEALBE account with your user's account.

#### Login

Use an exitsting HEALBE user account:

```swift
healbeSharedInstance.login(userName: "Joseph@gmail.com", password: "GreedIsGood") { result in
  switch result {
  case .success(_):
    print("We have successfully logged in")
  case .failure(let error):
    // HealbeError is container for errors
    print("Something goes wrong - \(error.error)")
  }
}
```

When you successfully log in, SDK changes it's state to one of **.profileNeedFill**, **.validNewUser** or **.validOldUser**

#### SignUp

Create a new HEALBE user account:

```swift
    healbeSharedInstance.signUp(userName: "Joseph@gmail.com",
                                password: "GreedIsGood",
                                allowMarketingCommunication: true) { result in
        switch result {
        case .success(_):
            print("We have successfully signed up")
        case .failure(let error):
            // HealbeError is container for errors
            print("Something goes wrong - \(error.error)")
        }
    }
```

When you successfully sign up, SDK changes it's state to **.profileNeedFill** and you should fill it with **HealbeSDKRoot.updateUser** method

### Connection process

GoBe device communicates with the mobile App via the BLE protocol. So, to start any communication with GoBe device, first of all, you need to prepare Bluetooth by 

```swift
    healbeSharedInstance.awakeBluetooth()

    // also you can get current bluetooth permission state and subscribe to its changed (available on iOS 13+)
    if #available(iOS 13, *) {
        let permission = healbeSharedInstance.bluetoothPermission
         healbeSharedInstance.bluetoothPermissionObserver = { bluetoothPermission in
            // add any action when permission is changed
        }
    }
```

Then you can scan for GoBe devices nearby and locate chosen GoBe device

```swift
  let myHealbeName = "Healbe GoBe 2"
  var myGoBe: GoBeStruct? = nil

  let connectionInterface: GoBeConnectInterface = HealbeSDK.healbeSharedInstance // right know we have one root object which implements a lot of protocols, maybe we will split it in future like we already did this with dataProvider
  
  connectionInterface.scan { (gobes, finished, error) in
    if let error = error {
      print("got error \(error)")
    }
    // we get new list of GoBe
    for gobe in gobes {
      print("name: \(gobe.name) | id: \(gobe.identifier)")
      if gobe.name == myHealbeName {
        // we found our gobe and can connect to it
        myGoBe = gobe
        break
      }
    }
    
    if finished {
      // the scan operation is over
      print("scan operation is finished")
    }
  }
```

You have found your GoBe and now you are ready to connect it. You need to pass selected GoBe and it's current 6-digit PIN-code. If you don't know the PIN, you can call connect without pin and SDK will apply default pin.

```swift
  connectionInterface.connect(gobe: myGoBe, pincode: "123456")
```

Current connection status can be determined via **gobeState** and it's observer which is a part of **GoBeConnectInterface**. If the passed PIN code is wrong, you will get **requestPin**. Prints below describe what actions from app SDK needs for current **gobeState**.

```swift

  connectionInterface.gobeStateObserver  = { state in
           switch state {
             case .ready:
               print("GoBe is connected to application and ready for working, updating current values and synchronization will star automaticaly")
             case .disconnected:
               print("GoBe is disconnected")
             case .needChangePin(let gobe):
               print("GoBe is connected, but with default pincode and pincode needs to be changed before using. Pincode is changed by GoBeConnectInterface.changePincode ")
           case .requestPin(let gobe, let wrongPin):
                print("Both of entered to connect pin and defaul pin are not correct for current gobe, you should enter another pin via calling GoBeConnectInterface.connect")
            case .needCriticalUpdate:
               print("GoBe is connected, but it needs to be updated before been used. You should start updating Gobe via method GoBeFunction.updateFirmware")
           case .notRegisteredOnServer:
                print("This state means that something wrong with Gobe and we can't fix it automatically. User should connect to our support")
           case .connected:
                print("This case means that BLE connection has been successfully established, but this is only one of the first stage of connection process which also contains authorizing, checking and updating some parameters on smartband, etc. No reaction is requered")
           default:
                print("All other values just show the current stage of the connection process and don't require any reaction from the app")
         }
    }
```

---
**NOTE**

SDK has to restart GoBe smartband and reconnect to it in some cases (for example, when you need user gender or date birth to be changed), so it is a correct situation when **gobeState** has changed to `disconnecting`, `connecting`, `connected`, etc few times after only one call **GoBeConnectInterface.connect()**

---

SDK remembers GoBe device after the first successful connection and will reconnect it automatically if GoBe is disconnected and discovered nearly again (by default). You can manage this autoconnection option by changing **connectionInterface.autoConnect** property value. Also you can disconnect GoBe device manually by calling **GoBeConnectInterface.disconnect()**

### Working with GoBe and current values

When GoBe connected and ready, you can interact with it: get current values of heart rate, skin contact status, and others, observe those values, start to estimate blood pressure, etc. Methods that implement these features are declared into **GoBeFunction protocol**. For example, if you want to control skin contact status, you should write something like the following code: 

```swift
    let gobeFunctions: GoBeFunction = HealbeSDK.healbeSharedInstance
        
    let fitStatus = gobeFunctions.skinContactStatus

    gobeFunctions.skinContactStatusObserver = { status in
        switch status {
        case .fitsFine:
            print("GoBe fits good and measures fine")
        case .takenOff:
            print("GoBe is taken off hand or it doesn't fit fine")
        case .none:
            print("GoBe is disconnected or it's state is unvailable")
          }
        }
        
    let heartRate = gobeFunctions.currentHeartInfo
        
    gobeFunctions.heartRateObserver = { heartRate
        print("User heart rate from GoBe is \(heartRate)")
    }
        
    let stressLevel = gobeFunctions.stressLevel
        
    gobeFunctions.stressLevel = { stressLevel in
        switch stressLevel {
        case .calculating: 
            print("User's stress level is calculating now")
        case .value(let value, let stressValueType):
            print("User's stress level is \(stressValueType) with value \(value)")
        case .none: 
            print("User's stress level in not avaialable now. It can be when GoBe skin contact status is not fitst fine")
            }
        }
}
```

\* GoBe needs some time to detect skin contact status changes (usually from 15 sec to 1 min).

### Health data

SDK syncs all user’s data with the HEALBE server. And it also gets data from the server (even if it was uploaded by another user’s mobile app / smartphone). The data is stored on mobile storage but also is being backed up to HEALBE server then internet connection is available.

You can get health data from SDK for a specific time via an instance which implements **SDKDataProvider** protocol. You can access that data even without GoBe connection using: 

```swift
  // get data provider
  let provider: SDKDataProvider = HealbeSDK.healbeSharedInstance.dataProvider

  let calendar = Calendar.current
  let curDate = Date()

  // today night
  let endDate = calendar.startOfDay(for: curDate.addingTimeInterval(24*60*60))
  // seven days ago date
  let startDate = calendar.startOfDay(for: endDate).addingTimeInterval(-7*24*60*60)

  // Get day summary values
  let energy = provider.energySummary(date: curDate)
  let hydra = provider.hydrationSummary(date: curDate)
  let stress = provider.stressSummary(date: curDate)
  let sleep = provider.sleepSummary(date: curDate)

  // get arrays of data, usually they are used to draw graphs 
  let pulseData = provider.pulseData(startDate: startDate, endDate: endDate)
  let energyShort = provider.energyData(startDate: startDate, endDate: curDate)
  let enxietyData = provider.anxietyData(startDate: startDate, endDate: endDate)
  let hydraData = provider.hydrationData(startDate: startDate, endDate: endDate)
  let stressData = provider.stressData(startDate: startDate, endDate: endDate)
```
### Weight module

The SDK provides the ability to work with the user's weight. There are two main entities in this module, these are "Weight" and "WeightGoal". The user can add/remove/edit these values. The SDK also synchronizes these values with the server.

You can get weight data from SDK for a specific time via an instance which implements **WeightLogicDataProvider** protocol. You can access that data event without GoBe connection using, but you need be authorized. SDK starts syncing values when the application starts and if the method is called.

```swift
        let weightProvider = HealbeSDK.healbeSharedInstance.weightLogicDataProvider
        
        // Get all weighs
        let weights = weightProvider.getAllWeight(ascending: false)
        
        // Delete weight
        if let weight = weights.first {
            try weightProvider.deleteWeight(weight)
        }
        
        // Create new weight
        let newWeight = Weight(date: Date(),
                               weightKG: 78.2,
                               unit: .kilograms,
                               source: .healbe)
        try weightProvider.saveWeight(newWeight
        
        let goalProvider: HealbeSDK.WeightGoalDataProvider = HealbeSDK.healbeSharedInstance.weightLogicDataProvider
        
        // Get all goals
        let goals = goalProvider.getAllGoals()
        
        // Create and save new weight. Only one goal can be active at a time
        let now = Date()
        let goalDate = now.addingTimeInterval(60*60*24*7)
        let newGoal = HealbeSDK.WeightGoal(startDate: now,
                                           goalDate: goalDate,
                                           startWeight: 86.2,
                                           goalWeight: 80,
                                           userComment: "I want to lose weight",
                                           status: .inProgress,
                                           plan: .fast,
                                           changeStatusDate: nil)
        
        // Start sync weight
        let synchronizationLogic: HealbeSDK.WeightLogicSynchronization = HealbeSDK.healbeSharedInstance.weightLogicDataProvider
        let isActive = synchronizationLogic.synchronizationIsActive
        
        if !isActive {
            weightProvider.startSynchronization { healbeErrors in
                // Synchronization does not end if an error occurred at one of the stages, 
                // but continues synchronization at the next stage.
            }
        }
```

You can observe the change of values and states inside the weight module. 
To do this, your class must implement the necessary protocol and subscribe to the changes.

```swift
    class WeightObserverClass: WeightDataProviderObserver {
        let provider: WeightDataProvider = HealbeSDK.healbeSharedInstance.weightLogicDataProvider
        
        var currentWeight: Weight?
        var weights: [Weight] = []
        
        func start() {
            self.currentWeight = self.provider.getLastWeight()
            self.weights = self.provider.getAllWeight(ascending: true)
            
            self.provider.addObserver(subscriber: self)
        }
        
        func stop() {
            self.provider.removeObserver(subscriber: self)
        }
        
        
        // MARK: - WeightDataProviderObserver
        
        func actualWeightDidChanged(_ weight: Weight?) {
            self.currentWeight = weight
        }
        
        func weightsDidChanged() {
            self.weights = self.provider.getAllWeights(ascending: true)
        }
    }
```

### Token module

The SDK allows you to manage tokens that will be sent to the server.

```swift
    let provider: TokenDataProvider = HealbeSDK.healbeSharedInstance.tokenDataProvider
        
    let allTokens = try provider.getAllTokens()
        
    if let token = allTokens.first {
        try provider.removeToken(token)
    }
        
    let newToken = Token(type: "type",
                         value: "value")
    provider.addToken(newToken)
```
