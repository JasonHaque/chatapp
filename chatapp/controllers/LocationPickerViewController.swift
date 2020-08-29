//
//  LocationPickerViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 29/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion : ((CLLocationCoordinate2D) -> Void)?
    
    private let map : MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    private var  coordinates : CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "pick a location"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send location" , style: .done, target: self, action: #selector(didTapSendLocation))
        view.addSubview(map)
        map.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
        
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        
        map.addGestureRecognizer(gesture)
        

     
    }
    
    @objc func didTapSendLocation(){
        
        guard let coordinates = self.coordinates else {
            return
        }
        
        completion?(coordinates)
        
        
    }
    
    @objc func didTapMap(_ gesture : UITapGestureRecognizer){
        
        let locationView = gesture.location(in: map)
        let coordinates = map.convert(locationView, toCoordinateFrom: map)
        
        self.coordinates = coordinates
        print(coordinates.latitude)
        print(coordinates.longitude)
        print("shit")
        //drop a pin so user can visually see where he tapped
        
        for annotation in map.annotations{
            map.removeAnnotation(annotation)
        }
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        
        map.addAnnotation(pin)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        map.frame = view.bounds
    }
    

    

}
