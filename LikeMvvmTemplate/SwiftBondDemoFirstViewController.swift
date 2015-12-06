// home: https://github.com/SwiftBond/Bond.git
// demo: https://github.com/SwiftBond/Bond-Demo-App.git

// 一方向バインド: ->> [Producer -> Bindable]
// 双方向バインド: ->>< [Producer(and Bindable) <-> Bindable(and Producer)]

// 考え方
// Producer・・・Observableを生成できる
// Observable・・・値の変化を逐次観測できる
// Bindable・・・Observableオブジェクトが変化した値を渡すインターフェースを提供する

import UIKit
import Bond

class SwiftBondDemoFirstViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        
        viewModel.username ->>< usernameTextField.bnd_text
        viewModel.password ->>< passwordTextField.bnd_text
        
        viewModel.activityIndicatorVisible ->> activityIndicator.bnd_animating
        viewModel.loginButtonEnabled ->> loginButton.bnd_enabled
        
        viewModel.loginState
            .observeNew { [unowned self] state in
                switch state {
                case .LoggedIn:
                    self.performSegueWithIdentifier("showSwiftBondDemoSecond", sender: self)
                    break
                default:
                    break
                }
        }
        
        loginButton.bnd_controlEvent
            .filter { $0 == UIControlEvents.TouchUpInside }
            .observeNew { [unowned self] event in
                self.viewModel.login()
        }
    }
}

private enum LoginState {
    case None
    case InProgress
    case LoggedIn
}

private class LoginViewModel {
    let username = Observable<String?>("Steve")
    let password = Observable<String?>("")
    
    let loginState = Observable<LoginState>(.None)
    
    private var loginInProgress: EventProducer<Bool> {
        return loginState.map { $0 == LoginState.InProgress }
    }
    
    var activityIndicatorVisible: EventProducer<Bool> {
        return loginInProgress
    }
    
    var loginButtonEnabled: EventProducer<Bool> {
        let usernameValid = username.map { $0!.characters.count > 2 }
        let passwordValid = password.map { $0!.characters.count > 2 }
        return usernameValid
            .combineLatestWith(passwordValid)
            .combineLatestWith(loginInProgress)
            .map { inputs, progress in
                inputs.0 == true && inputs.1 == true && progress == false
        }
    }
    
    func login() {
        loginState.value = .InProgress
        Mock.performDelay(1) { self.loginState.value = .LoggedIn }
    }
}
