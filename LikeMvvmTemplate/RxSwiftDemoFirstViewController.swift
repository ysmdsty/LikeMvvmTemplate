import UIKit
import RxSwift
import RxCocoa

class RxSwiftDemoFirstViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private let viewModel = LoginViewModel()
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        
        
        viewModel.username.bindTo(usernameTextField.rx_text).addDisposableTo(disposeBag)
        usernameTextField.rx_text.bindTo(viewModel.username).addDisposableTo(disposeBag)
        
        viewModel.password.bindTo(passwordTextField.rx_text).addDisposableTo(disposeBag)
        passwordTextField.rx_text.bindTo(viewModel.password).addDisposableTo(disposeBag)
        
        viewModel.activityIndicatorVisible.bindTo(activityIndicator.rx_animating).addDisposableTo(disposeBag)
        viewModel.loginButtonEnabled.bindTo(loginButton.rx_enabled).addDisposableTo(disposeBag)
        
        viewModel.loginState
            .subscribeNext { [unowned self] (state) in
                switch state {
                case .LoggedIn:
                    self.performSegueWithIdentifier("showSwiftBondDemoSecond", sender: self)
                    break
                default:
                    break
                }
            }.addDisposableTo(disposeBag)
        
        loginButton.rx_controlEvents(.TouchUpInside)
            .subscribeNext {
                [unowned self] in
                self.viewModel.login()
            }.addDisposableTo(disposeBag)
    }
}

private enum LoginState {
    case None
    case InProgress
    case LoggedIn
}

private class LoginViewModel {
    var username = Variable("Stave")
    var password = Variable("")
    
    let loginState = Variable(LoginState.None)
    
    private var loginInProgress: Observable<Bool> {
        return loginState.map { $0 == LoginState.InProgress }.shareReplay(1)
    }
    
    var activityIndicatorVisible: Observable<Bool> {
        return loginInProgress.shareReplay(1)
    }
    
    var loginButtonEnabled: Observable<Bool> {
        let usernameValid = username.map { $0.characters.count > 2 }
        let passwordValid = password.map { $0.characters.count > 2 }
        return combineLatest(usernameValid, passwordValid){($0,$1)}
            .map {
                return $0 && $1}
            .shareReplay(1)
    }
    
    func login() {
        loginState.value = .InProgress
        Mock.performDelay(1) { self.loginState.value = .LoggedIn }
    }
}
