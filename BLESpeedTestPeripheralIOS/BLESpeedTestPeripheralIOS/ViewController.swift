import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {
    
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    let serviceUUID: CBUUID = CBUUID(string: "5fbfb456-a20b-478f-889c-b3fa3329cd7d")
    let writeCharacteristicUUID: CBUUID = CBUUID(string: "6bebf1b3-e6fd-47a4-8ed9-b36365c3e654")
    let readCharacteristicUUID: CBUUID = CBUUID(string: "bc30689f-9105-4789-b2e9-8865637f50a0")
    
    let identifier = Bundle.main.bundleIdentifier!
    
    var peripheralManager: CBPeripheralManager?
    var writeCharacteristic:CBMutableCharacteristic?
    var readCharacteristic:CBMutableCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }

    @IBAction func startAdvertising(_ sender: Any) {
        startButton.isEnabled = false
        stopButton.isEnabled = true
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [serviceUUID]])
    }
    
    @IBAction func stopAdvertising(_ sender: Any) {
        startButton.isEnabled = true
        stopButton.isEnabled = false
        peripheralManager?.stopAdvertising()
        log("Stopped advertising as BLE peripheral.")
    }
    
    @IBAction func clearLog(_ sender: Any) {
        logView.text = ""
    }
    
    func log(_ message: String) {
        logView.text.append("\(message)\n")
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            log("Bluetooth is not turned on.")
            self.stopAdvertising(stopButton as Any)
            return
        }
        self.writeCharacteristic = CBMutableCharacteristic(type: writeCharacteristicUUID, properties: .write, value: nil, permissions: .writeable)
        self.readCharacteristic = CBMutableCharacteristic(type: readCharacteristicUUID, properties: .notify, value: nil, permissions: .readable)
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [self.writeCharacteristic!, self.readCharacteristic!]
        self.peripheralManager?.add(service)
    }
    
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log("Started advertising as BLE peripheral.")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log("Incoming connection from Central \(central.identifier) received.")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log("Central \(central.identifier) has closed the connection.")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if (request.characteristic.uuid == writeCharacteristicUUID) {
                log("Received \(request.value ?? Data()) Bytes from Central")
                peripheral.respond(to: request, withResult: .success)
                let data = Data([0x00])
                peripheral.updateValue(data, for: self.readCharacteristic!, onSubscribedCentrals: [request.central])
            }
        }
    }
}

