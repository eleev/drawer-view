//
//  ViewController.swift
//  demo
//
//  Created by Astemir Eleev on 26/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//  Modified by Mitchell Tucker on 3/10/2020 under the MIT license agreement

import UIKit
import SideDrawer
import MapKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDataSource {

    private var drawerView: SideDrawerView!
    enum contentView {
        case map
        case tableView
        case collectionView
        case none
    }
    
    // .map
    // .tableView
    // .collectionView
    // .none
    private var content:contentView = .map /// change this get different demos
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        

        switch(content){
        case .map:
            var height:CGFloat?
            if view.bounds.height > view.bounds.width{
                height = view.frame.height
            }else{
                height = view.frame.width
            }
            drawerView = SideDrawerView(
                                        drawerHandleWidth: 10,
                                        drawerHeight: height!,
                                        flipHeightWidthOnRotation: true,
                                        useSafeAreaLayoutGuide: true,
                                        useTopSafeArea: false,
                                        setContentInSafeArea: false,
                                        blurStyle: .dark ,
                                        lineArrow: (100, 5, UIColor.white),
                                        drawerBackgroundColor: UIColor.clear,
                                        superView: view)
            
            let mapView = MKMapView()
            drawerView.setContentView(view: mapView)
            
            
        case .tableView:
            var height:CGFloat?
            if view.bounds.height > view.bounds.width{
                height = view.frame.height / 2
            }else{
                height = view.frame.width / 2
            }
            drawerView = SideDrawerView(
                                    drawerHandleWidth: 50,
                                    drawerHeight: height!,
                                    flipHeightWidthOnRotation: true,
                                    useSafeAreaLayoutGuide: true,
                                    drawerBackgroundColor:UIColor(displayP3Red: 255, green: 0, blue: 0, alpha: 0.1),
                                    superView: view)
            
            let tableView = UITableView()
            tableView.backgroundColor = .clear
            tableView.delegate = self
            tableView.dataSource = self
            drawerView.setContentView(view:tableView)
        
            
        case .collectionView:
            drawerView = SideDrawerView(
                                    drawerHandleWidth: 25,
                                    drawerHeight: 100,
                                    flipHeightWidthOnRotation: true,
                                    useSafeAreaLayoutGuide: false,
                                    useTopSafeArea: false,
                                    setContentInSafeArea: true,
                                    blurStyle: .regular,
                                    superView: view)
            drawerView.cornerRadius = 30
            

            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout.init())
            collectionView.backgroundColor = .clear
            collectionView.register(UINib(nibName: "MyCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
            
            collectionView.delegate = self
            collectionView.dataSource = self
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.scrollDirection = .horizontal
            }
            drawerView.setContentView(view:collectionView)
            // Stack view change
            //if orientation.isPortrait{
            //    stackView.axis = .horizontal
            //}else{
            //    stackView.axis = .vertical
            //}
            drawerView.onOrientaitonChange = { orientaiton in
                
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    switch orientaiton {
                    case .portrait:
                        flowLayout.scrollDirection = .horizontal
                    case .portraitUpsideDown:
                        flowLayout.scrollDirection = .horizontal
                    case .landscapeLeft:
                        flowLayout.scrollDirection = .vertical
                    case .landscapeRight:
                        flowLayout.scrollDirection = .vertical
                    case .faceUp:
                        return
                    case .faceDown:
                        return
                    case .unknown:
                        return
                    @unknown default:
                        return
                    }
                }
              }
            
  
        case .none:
            let _ = SideDrawerView(superView: view)
            //let _ = SideDrawerView( drawerHandleWidth: 50, drawerHeight: 100,flipHeightWidthOnRotation: false ,superView: view)
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    /// DEMO STUFF
    
    var state_names = ["Alaska", "Alabama", "Arkansas", "American Samoa", "Arizona", "California", "Colorado", "Connecticut", "District of Columbia", "Delaware", "Florida", "Georgia", "Guam", "Hawaii", "Iowa", "Idaho", "Illinois", "Indiana", "Kansas", "Kentucky", "Louisiana", "Massachusetts", "Maryland", "Maine", "Michigan", "Minnesota", "Missouri", "Mississippi", "Montana", "North Carolina", "North Dakota", "Nebraska", "New Hampshire", "New Jersey", "New Mexico", "Nevada", "New York", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Virginia", "Virgin Islands", "Vermont", "Washington", "Wisconsin", "West Virginia", "Wyoming"]
    
    var emoji = ["😀", "😁", "😂", "🤣", "😃", "😄", "😅", "😆", "😉", "😊", "😋", "😎", "😍", "😘", "😗", "😙", "😚", "☺", "🙂", "🤗", "🤔", "😐", "😑", "😶", "🙄", "😏", "😣", "😥", "😮", "🤐", "😯", "😪", "😫", "😴", "😌", "🤓", "😛", "😜", "😝", "🤤", "😒", "😓", "😔", "😕", "🙃", "🤑", "😲", "☹", "🙁", "😖", "😞", "😟", "😤", "😢", "😭", "😦", "😧", "😨", "😩", "😬", "😰", "😱", "😳", "😵", "😡", "😠", "😇", "🤠", "🤡", "🤥", "😷", "🤒", "🤕", "🤢", "🤧", "😈", "👿", "👹", "👺", "💀", "☠", "👻", "👽", "👾", "🤖", "💩"]

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state_names.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
            }
            cell?.backgroundColor = .clear
        cell?.textLabel?.backgroundColor = .clear
            cell?.textLabel!.text = self.state_names[indexPath.row]

            return cell!
        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    
    // CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emoji.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! MyCollectionViewCell
        
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.label.text = self.emoji[indexPath.row] // The row value is the same as the index of the desired text within the array.
        cell.backgroundColor = UIColor.clear // make cell more visible in our example project
        
        return cell
    }
    
    
    
    
}
