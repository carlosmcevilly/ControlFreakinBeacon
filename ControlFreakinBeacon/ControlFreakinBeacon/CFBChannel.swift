//
//  CFBChannel.swift
//  ControlFreakinBeacon
//
//  Created by bone on 7/11/15.
//  Copyright (c) 2015 Panopy. All rights reserved.
//


import UIKit
import CoreLocation
import CoreBluetooth

let kCFBBeaconEnabledDurationSeconds = 1
let kCFBBeaconGUIDString = "ED543D05-42DC-4D1C-9CCD-41A8D5FFF34D"

public typealias CFBAction = [() -> ()]
public typealias CFBConfig = [String:CFBAction]?

public protocol CBFDelegate {
	func didStartTransmitting()
	func didStopTransmitting()
}


public class CFBController: NSObject, CBPeripheralManagerDelegate, CLLocationManagerDelegate {

	static var sharedController: CFBController? = nil

	let clManager: CLLocationManager
	let beaconID: String
	let uuid: NSUUID
	var actionDelegate: CBFDelegate?
	var peripheralManager: CBPeripheralManager?
	var region: CLBeaconRegion?
	var power: NSNumber?
	var config: CFBConfig

	init(beaconID: String = kCFBBeaconGUIDString, actionDelegate: CBFDelegate, config: CFBConfig) {
		self.clManager = CLLocationManager()
		self.beaconID = beaconID
		self.uuid = NSUUID(UUIDString: self.beaconID)!
		super.init()
		self.clManager.delegate = self
	}

	public class func sharedController(actionDelegate: CBFDelegate, config: CFBConfig) -> CFBController {
		if let controller = sharedController {
			return controller
		}
		else {
			sharedController = CFBController(delegate: actionDelegate, config:config)
			return sharedController!
		}
	}


	/**

	vc loads
	let config: [String, ]
	let sharedController = CFBController.sharedController(self, config)


	**/

	public func startTransmitter() {
		startMonitoringPeripheral()
		// start spinner here
		dispatch_after(DISPATCH_TIME_NOW, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.peripheralManager!.stopAdvertising()
			// top spinner here
			self.peripheralManager!.delegate = nil
			self.peripheralManager = nil;
		})
	}

	public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
		if peripheral.state as CBPeripheralManagerState == CBPeripheralManagerState.PoweredOn {
			updateAdvertisedRegion()
		}
	}

	func startMonitoringPeripheral() {
		if let manager = peripheralManager {
			manager.delegate = self
		}
		else {
			peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0))
		}
	}

	func updateAdvertisedRegion() {
		peripheralManager?.stopAdvertising()
		let power = -59 as NSNumber
		var peripheralData = beaconRegion.peripheralDataWithMeasuredPower(power)
		if let data = peripheralData {
			peripheralManager?.startAdvertising(data as [NSObject : AnyObject])
		}
	}


	// Mark Shared
	var beaconRegion: CLBeaconRegion {
		if region == nil {
			region = CLBeaconRegion(proximityUUID: uuid, major: 0 as CLBeaconMajorValue, minor: 0 as CLBeaconMinorValue, identifier: beaconID)
		}
		return region!
	}


	// Mark Receiver

	public func startMonitoringBeaconRegion() {
		clManager.startMonitoringForRegion(self.beaconRegion as CLRegion)
		if !CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) {
			println("nope")
		}
	}

	public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
		let immediateBeacons = beacons.filter() { ($0 as! CLBeacon).proximity == .Immediate }
		var closestBeacon: CLBeacon?
		if immediateBeacons.count > 0 {
			closestBeacon = immediateBeacons.first! as? CLBeacon
		}
		if closestBeacon == nil {
		}
	}

	/**
	NSString *uuid = foundBeacon.proximityUUID.UUIDString;
	NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
	NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
	NSString *identifier = [NSString stringWithFormat:@"%@:%@:%@", uuid, major, minor];
	**/

}





/*

@IBOutlet startStopButton: UIButton?
@IBOutlet statusLabel: UILabel?
@IBOutlet spinner: UIActivityIndicatorView?

self.statusLabel.hidden = YES;
self.startButton.hidden = NO;

NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
NSInteger count = [defaults integerForKey:kSQTSetupAlertShownCount];
if (count < kSQTSetupAlertMaxTimesToShow) {
count++;
[[[UIAlertView alloc] initWithTitle:@"Setup" message:@"Before using this, please change your PPI settings:\n\n1) Turn on Monitor Beacons\n\n2) set Notifications settings to show up to 10 recent items.\n\nBe sure to re-launch PPI at least once after first enabling Monitor Beacons." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
[defaults setInteger:count forKey:kSQTSetupAlertShownCount];
[defaults synchronize];

*/

