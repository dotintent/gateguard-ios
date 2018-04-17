//
//  ViewController.swift
//  gateguard
//
//  Created by Sławek Peszke on 04/12/2017.
//  Copyright © 2017 inFullMobile. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var activateBluetoothLabel: UILabel!
    @IBOutlet weak var keyStateSwitch: UISwitch!
    
    let bleService = BLEService()
    let tokenService = TokenServiceImpl()

    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uiSetup()
        self.bleSetup()
        self.providersSetup()
        self.tokenExchangeSetup()
    }

    // MARK: Setup
    
    private func uiSetup() {
        let layer = self.activateBluetoothLabel.layer
        layer.cornerRadius = 5.0
    }
    
    private func bleSetup() {
        self.bleService.delegate = self
    }
    
    private func providersSetup() {
        self.bleService.electronicKeyStateProvider = { [unowned self] in
            return self.keyStateSwitch.isOn
        }
    }
    
    private func tokenExchangeSetup() {
        self.bleService.tokenDidRequestCallback = { [weak tokenService, weak bleService] (_ tokenId: Int) in
            
            tokenService?.getToken(with: tokenId) { (_ result) in
                switch result {
                case .success(let token):
                    bleService?.respond(withToken: token)
                case .error(let error):
                    let errorMessage = String(describing: error)
                    print("Error: \(errorMessage)")
                }
            }
        }
    }
    
    // MARK: Actions

    @IBAction func keyStateDidChange(_ sender: UISwitch) {
        if sender.isOn {
            self.bleService.activate()
        } else {
            self.bleService.deactivate()
        }
    }
}

// MARK: - BLEServiceDelegate

extension MainViewController: BLEServiceDelegate {
    func bleService(_ service: BLEService, bluetoothStateDidChange isActive: Bool) {
        self.keyStateSwitch.isEnabled = isActive
        self.activateBluetoothLabel.isHidden = isActive
    }
}
