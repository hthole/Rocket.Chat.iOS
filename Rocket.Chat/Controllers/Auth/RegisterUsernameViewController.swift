//
//  RegisterUsernameViewController.swift
//  Rocket.Chat
//
//  Created by Rafael Kellermann Streit on 04/03/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import UIKit
import SwiftyJSON

final class RegisterUsernameViewController: BaseViewController {

    internal var requesting = false

    var serverPublicSettings: AuthSettings?

    @IBOutlet weak var visibleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        startLoading()
        AuthManager.usernameSuggestion { [weak self] (response) in
            self?.stopLoading()

            if !response.isError() {
                self?.textFieldUsername.text = response.result["result"].string ?? ""
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )

        textFieldUsername.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }

    func startLoading() {
        textFieldUsername.alpha = 0.5
        requesting = true
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        textFieldUsername.alpha = 1
        requesting = false
        activityIndicator.stopAnimating()
    }

    // MARK: Keyboard Handlers
    override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            visibleViewBottomConstraint.constant = keyboardSize.height
        }
    }

    override func keyboardWillHide(_ notification: Notification) {
        visibleViewBottomConstraint.constant = 0
    }

    // MARK: Request username
    fileprivate func requestUsername() {
        startLoading()

        AuthManager.setUsername(textFieldUsername.text ?? "") { [weak self] (response) in
            self?.stopLoading()

            if response.isError() {
                if let error = response.result["error"].dictionary {
                    let alert = UIAlertController(
                        title: localizedString("error.socket.default_error_title"),
                        message: error["message"]?.string ?? localizedString("error.socket.default_error_message"),
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

}

extension RegisterUsernameViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !requesting
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        requestUsername()
        return true
    }

}