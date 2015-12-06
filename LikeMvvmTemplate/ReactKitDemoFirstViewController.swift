import UIKit
import ReactKit

class ReactKitDemoFirstViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        usernameTextField.text = "stave"
        self.viewModel.username = usernameTextField.textChangedStream() |> startWith(usernameTextField.text)
        self.viewModel.password = passwordTextField.textChangedStream() |> startWith(passwordTextField.text)

        (self.loginButton, "enabled") <~ viewModel.loginButtonEnabled.ownedBy(self)

        //TODO: 遷移先を作る
        ^{ _ in self.performSegueWithIdentifier("showSwiftBondDemoSecond", sender: self) } <~ loginButton.buttonStream({ return $0}).ownedBy(self)
    }
}

private enum LoginState {
    case None
    case InProgress
    case LoggedIn
}

private class LoginViewModel {
    var username: Stream<String?>!
    var password: Stream<String?>!

    var loginButtonEnabled: Stream<NSNumber?> {
        let usernameValid: Stream<Bool> = username |> map {$0!.characters.count > 2}
        let passwordValid: Stream<Bool> = password |> map {$0!.characters.count > 2}
        let combinedTextStream = [usernameValid, passwordValid] |> combineLatestAll
        return combinedTextStream |> map { (values: [Bool]) -> NSNumber in
            return NSNumber(bool: values[0] && values[1])
        }
    }

    
}
