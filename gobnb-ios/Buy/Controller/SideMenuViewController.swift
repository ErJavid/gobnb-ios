//
//  SideMenuTableViewController.swift
//  gobnb-ios
//
//  Created by Hammad Tariq on 17/07/2019.
//  Copyright © 2019 Hammad Tariq. All rights reserved.
//

import UIKit
import SideMenu

class SideMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    let navArray = ["Your Orders", "Payment", "Settings", "Help"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 65.0
    }
    
    override func viewDidLayoutSubviews() {
        tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.size.width, height: tableView.contentSize.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.size.width, height: tableView.contentSize.height)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "sellSideNav"
        {
            print("sellSideNav")
            UserDefaults.standard.set("sellSideNav", forKey: "StartSideVC")
        }
    }

    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return navArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        }
        if self.navArray.count > 0 {
            cell?.textLabel!.text = self.navArray[indexPath.row]
        }
        cell?.textLabel?.numberOfLines = 0
        
        return cell!
    }
}