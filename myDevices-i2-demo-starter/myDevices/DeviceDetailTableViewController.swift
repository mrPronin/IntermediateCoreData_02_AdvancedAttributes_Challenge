/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreData

class DeviceDetailTableViewController: UITableViewController {
    var device: Device?
    var coreDataStack: CoreDataStack!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var deviceTypeTextField: UITextField!
    @IBOutlet weak var deviceOwnerLabel: UILabel!
    @IBOutlet weak var deviceIdentifierTextField: UITextField!
    @IBOutlet weak var purchaseDateTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    private let datePicker = UIDatePicker()
    private var selectedDate: NSDate?
    private lazy var dateFormatter: NSDateFormatter = {
        let df = NSDateFormatter()
        df.timeStyle = .NoStyle
        df.dateStyle = .MediumStyle
        
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.addTarget(self, action: "datePickerValueChanged:", forControlEvents: .ValueChanged)
        datePicker.datePickerMode = .Date
        purchaseDateTextField.inputView = datePicker
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let device = device {
            nameTextField.text = device.name
            deviceTypeTextField.text = device.deviceType
            deviceIdentifierTextField.text = device.deviceID
            
            if let owner = device.owner {
                deviceOwnerLabel.text = "Device owner: \(owner.name)"
            } else {
                deviceOwnerLabel.text = "Set device owner"
            }
            
            if let purchaseDate = device.purchaseDate {
                selectedDate = purchaseDate
                datePicker.date = purchaseDate
                purchaseDateTextField.text = dateFormatter.stringFromDate(purchaseDate)
                
                coreDataStack.managedObjectContext.refreshObject(device, mergeChanges: true)
                if let birthdayBuddies = device.valueForKey("purchasedOnSameDate") as? [Device] {
                    for birthdayBuddy in birthdayBuddies {
                        print("Birthday buddy! - \(birthdayBuddy.name)")
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let device = device, name = nameTextField.text, deviceType = deviceTypeTextField.text {
            device.name = name
            device.deviceType = deviceType
            device.deviceID = deviceIdentifierTextField.text
            device.purchaseDate = selectedDate
        } else if device == nil {
            if let name = nameTextField.text, deviceType = deviceTypeTextField.text, entity = NSEntityDescription.entityForName("Device", inManagedObjectContext: coreDataStack.managedObjectContext) where !name.isEmpty && !deviceType.isEmpty {
                device = Device(entity: entity, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
                device?.name = name
                device?.deviceType = deviceType
                device?.deviceID = deviceIdentifierTextField.text
                device?.purchaseDate = selectedDate
            }
        }
        
        coreDataStack.saveMainContext()
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            if let personPicker = storyboard?.instantiateViewControllerWithIdentifier("People") as? PeopleTableViewController {
                personPicker.coreDataStack = coreDataStack
                
                // more personPicker setup code here
                personPicker.pickerDelegate = self
                personPicker.selectedPerson = device?.owner
                
                navigationController?.pushViewController(personPicker, animated: true)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func datePickerValueChanged(datePicker: UIDatePicker) {
        purchaseDateTextField.text = dateFormatter.stringFromDate(datePicker.date)
        selectedDate = dateFormatter.dateFromString(purchaseDateTextField.text!)
    }
}

extension DeviceDetailTableViewController: PersonPickerDelegate {
    func didSelectPerson(person: Person) {
        device?.owner = person
        
        coreDataStack.saveMainContext()
    }
}
