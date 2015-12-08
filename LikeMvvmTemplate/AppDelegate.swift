import UIKit

class Mock {
    static func performDelay(delayTime: UInt64 ,closure: (()->())) {
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayTime * NSEC_PER_SEC))
        dispatch_after(dispatchTime, dispatch_get_main_queue()) {
            closure()
        }
    }
    static func dispatchAsyncMain(closure: (()->())){
        dispatch_async(dispatch_get_main_queue()) {
            closure()
        }
    }
    static func dispatchAsyncGlobal(closure: (()->())){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            closure()
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

}
