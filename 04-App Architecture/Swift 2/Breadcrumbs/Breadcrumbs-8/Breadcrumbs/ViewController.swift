//
//  ViewController.swift
//  Breadcrumbs
//
//  Created by Nicholas Outram on 20/01/2016.
//  Copyright © 2016 Plymouth University. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, BCOptionsSheetDelegate {
    /// The application state - "where we are in a known sequence"
    enum AppState {
        case WaitingForViewDidLoad
        case RequestingAuth
        case LiveMapNoLogging
        case LiveMapLogging
        
        init() {
            self = .WaitingForViewDidLoad
        }
        
    }
    
    /// The type of input (and its value) applied to the state machine
    enum AppStateInputSource {
        case None
        case Start
        case AuthorisationStatus(Bool)
        case UserWantsToStart(Bool)
    }
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startButton: UIBarButtonItem!
    @IBOutlet weak var stopButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var optionsButton: UIBarButtonItem!

    // MARK: - Properties
    lazy var locationManager : CLLocationManager = {

        let loc = CLLocationManager()
        
        //Set up location manager with defaults
        loc.desiredAccuracy = kCLLocationAccuracyBest
        loc.distanceFilter = kCLDistanceFilterNone
        loc.delegate = self
        
        //Optimisation of battery
        loc.pausesLocationUpdatesAutomatically = true
        loc.activityType = CLActivityType.Fitness
        loc.allowsBackgroundLocationUpdates = false
        
        return loc
    }()
    
    //Applicaion state
    private var state : AppState = AppState() {
        willSet {
            print("Changing from state \(state) to \(newValue)")
        }
        didSet {
            self.updateOutputWithState()
        }
    }
    
    private var options : BCOptions = BCOptions() {
        didSet {
            options.updateDefaults()
            BCOptions.commit()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.updateStateWithInput(.Start)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.AuthorizedAlways {
            self.updateStateWithInput(.AuthorisationStatus(true))
        } else {
            self.updateStateWithInput(.AuthorisationStatus(false))
        }
    }
    
    // MARK: Action and Events
    @IBAction func doStart(sender: AnyObject) {
        self.updateStateWithInput(.UserWantsToStart(true))
    }
    
    @IBAction func doStop(sender: AnyObject) {
        self.updateStateWithInput(.UserWantsToStart(false))
    }
    
    @IBAction func doClear(sender: AnyObject) {
        
    }
    
    @IBAction func doOptions(sender: AnyObject) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ModalOptions" {
            if let dstVC = segue.destinationViewController as? BCOptionsTableViewController {
                dstVC.delegate = self
            }
        }
    }
    
    // MARK: State Machine
    //UPDATE STATE
    func updateStateWithInput(ip : AppStateInputSource)
    {
        var nextState = self.state
        
        switch (self.state) {
        case .WaitingForViewDidLoad:
            if case .Start = ip {
                nextState = .RequestingAuth
            }
            
        case .RequestingAuth:
            if case .AuthorisationStatus(let val) = ip where val == true {
                nextState = .LiveMapNoLogging
            }

        case .LiveMapNoLogging:
            
            //Check for user cancelling permission
            if case .AuthorisationStatus(let val) = ip where val == false {
                nextState = .RequestingAuth
            }
            
            //Check for start button
            else if case .UserWantsToStart(let val) = ip where val == true {
                nextState = .LiveMapLogging
            }
            
        case .LiveMapLogging:
            
            //Check for user cancelling permission
            if case .AuthorisationStatus(let val) = ip where val == false {
                nextState = .RequestingAuth
            }
            
            //Check for stop button
            else if case .UserWantsToStart(let val) = ip where val == false {
                nextState = .LiveMapNoLogging
            }
        }
        
        self.state = nextState
    }
    
    //UPDATE (MOORE) OUTPUTS
    func updateOutputWithState() {
        
        switch (self.state) {
        case .WaitingForViewDidLoad:
            break
            
        case .RequestingAuth:
            locationManager.requestAlwaysAuthorization()
            
            //Set UI into default state until authorised
            
            //Buttons
            startButton.enabled   = false
            stopButton.enabled    = false
            clearButton.enabled   = false
            optionsButton.enabled = false
            
            //Map defaults (pedantic)
            mapView.delegate = nil
            mapView.showsUserLocation = false
            
            //Location manger (pedantic)
            locationManager.stopUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = false
            
        case .LiveMapNoLogging:
            
            //Buttons for logging
            startButton.enabled = true
            stopButton.enabled = false
            optionsButton.enabled = true
            
            //Live Map
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .Follow
            mapView.showsTraffic = true
            mapView.delegate = self
            
        case .LiveMapLogging:
            //Buttons
            startButton.enabled   = false
            stopButton.enabled    = true
            optionsButton.enabled = true
            
            //Map
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .Follow
            mapView.showsTraffic = true
            mapView.delegate = self
            
        }
    }

    // MARK: - BCOptionsSheetDelegate
    func dismissWithUpdatedOptions(updatedOptions : BCOptions?) {
        self.dismissViewControllerAnimated(true) {
            if let op = updatedOptions {
                self.options = op
            }
        }
    }
    
}

