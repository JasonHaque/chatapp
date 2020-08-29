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
    private var  coordinates : CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map : MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    init(coordinates : CLLocationCoordinate2D?){
        if let coord = coordinates {
            self.coordinates = coord
            self.isPickable = false
          
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        if isPickable == true {
            print("authorized")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send location" , style: .done, target: self, action: #selector(didTapSendLocation))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            
            map.addGestureRecognizer(gesture)
        }
            
        else{
            guard let coordinates = self.coordinates else {
                return
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            
            map.addAnnotation(pin)
            
        }
        
        view.addSubview(map)
       
        

     
    }
    
    @objc func didTapSendLocation(){
        
        guard let coordinates = self.coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
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
