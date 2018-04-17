//
//  BLEService.swift
//  gateguard
//
//  Created by Sławek Peszke on 07/12/2017.
//  Copyright © 2017 inFullMobile. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BLEServiceDelegate: class {
    func bleService(_ service: BLEService, bluetoothStateDidChange isActive: Bool)
}

final class BLEService: NSObject {
    
    // MARK: Properties
    
    private var centralManager: CBCentralManager!
    
    private var storedPeripheral: CBPeripheral?
    private var storedCharacteristic: CBCharacteristic?
    
    var tokenDidRequestCallback: ((_ tokenId: Int) -> Void)?
    
    private var isElectronicKeyActive: Bool {
        return self.electronicKeyStateProvider()
    }
    var electronicKeyStateProvider: (() -> Bool) = { return true }
    
    weak var delegate: BLEServiceDelegate?
    
    // MARK: Init
    
    override init() {
        super.init()

        self.setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func respond(withToken token: Token) {
        guard let peripheral = self.storedPeripheral, let characteristic = self.storedCharacteristic else { return }

        let value = "\(token.id)|\(token.uuid.uuidString)"
        if let data = value.data(using: .utf8, allowLossyConversion: true) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else {
            fatalError("Couldn't encode Token's UUID")
        }
    }
    
    // MARK: Management

    func activate() {
        guard self.centralManager.state == .poweredOn else { return }
        self.scanForPeripheral()
    }
    
    func deactivate() {
        guard let peripheral = self.storedPeripheral, self.centralManager.state == .poweredOn else { return }
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: Extensions

extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.delegate?.bleService(self, bluetoothStateDidChange: true)
            self.scanForPeripheral()
        default:
            self.delegate?.bleService(self, bluetoothStateDidChange: false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        self.centralManager.stopScan()
        
        if self.storedPeripheral != peripheral {
            self.storedPeripheral = peripheral
        }
        
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.storedPeripheral = nil
        self.storedCharacteristic = nil
        
        self.scanForPeripheral()
    }
    
    // MARK: Helpers
    
    private func scanForPeripheral() {
        guard self.isElectronicKeyActive else { return }
        
        self.centralManager.scanForPeripherals(withServices: [CBUUID.serviceUUID],
                                               options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(booleanLiteral: true)])
    }
}

extension BLEService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        
        guard let service = peripheral.services?.filter({ $0.uuid == CBUUID.serviceUUID }).first else {
            return
        }
        
        peripheral.discoverCharacteristics([CBUUID.newTokenNotificationCharacteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.filter({ $0.uuid == CBUUID.newTokenNotificationCharacteristicUUID }).first else {
            return
        }
        self.storedCharacteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value,
            let receivedText = String(data: data, encoding: .utf8),
            let tokenId = Int(receivedText) else { return }

        self.tokenDidRequestCallback?(tokenId)
    }
}

extension CBUUID {
    
    // MARK: Properties

    static var serviceUUID: CBUUID {
        return CBUUID(string: "93384AB6-9EB1-4AF2-90FB-F88ABB6F79AF")
    }

    static var newTokenNotificationCharacteristicUUID: CBUUID {
        return CBUUID(string: "4E98BE1C-F8D9-46AD-9D08-C0AAA7DFEE7A")
    }
}
