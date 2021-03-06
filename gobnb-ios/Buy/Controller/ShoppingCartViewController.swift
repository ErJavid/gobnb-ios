//
//  ShoppingCartViewController.swift
//  gobnb-ios
//
//  Created by Hammad Tariq on 03/07/2019.
//  Copyright © 2019 Hammad Tariq. All rights reserved.
//

import UIKit
import SwipeCellKit
import SVProgressHUD
import Alamofire
import SwiftyJSON
import SwiftKeychainWrapper

protocol CartItemTableViewCellDelegate {
    func showDeleteButtonOnSwipe(tableView: UITableView, at indexPath: IndexPath)
    func qtyChanged()
}

class CartItemTableViewCell: SwipeTableViewCell {
    
    @IBOutlet weak var qtyLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    
    var idOfTheRecord : String = ""
    var tableView: UITableView?
    var indexPath: IndexPath?
    var cartItemDelegate: CartItemTableViewCellDelegate?
    @IBAction func subtractButtonDidPress(_ sender: Any) {
        let newQty = Int(qtyLabel.text!)! - 1
        if(newQty > 0){
            qtyLabel.text = "\(newQty)"
            
            var i = 0;
            for var item in ShoppingCartModel.shoppingCartArray
            {
                if item.id == idOfTheRecord {
                    item.qty = item.qty - 1
                    var itemPriceAfterQty = Double(item.qty) * item.price
                    itemPriceAfterQty = round (itemPriceAfterQty * 1000)/1000
                    itemPriceLabel.text = "\(itemPriceAfterQty) \(UserDefaults.standard.string(forKey: "storeBaseCurrency") ?? "")"
                    ShoppingCartModel.shoppingCartArray[i] = item
                    break
                }
                i = i+1;
            }
            Helper().updateCartPriceAndQty() //update global cart user defaults
            cartItemDelegate?.qtyChanged()
        }else{
            cartItemDelegate?.showDeleteButtonOnSwipe(tableView: tableView!, at: indexPath!)
        }
    }
    
    @IBAction func addButtonDidPress(_ sender: Any) {
        let newQty = Int(qtyLabel.text!)! + 1
        if(newQty < 10){
            qtyLabel.text = "\(newQty)"
            
            var i = 0;
            for var item in ShoppingCartModel.shoppingCartArray
            {
                if item.id == idOfTheRecord {
                    item.qty = item.qty + 1
                    var itemPriceAfterQty = Double(item.qty) * item.price
                    itemPriceAfterQty = round (itemPriceAfterQty * 1000)/1000
                    itemPriceLabel.text = "\(itemPriceAfterQty) \(UserDefaults.standard.string(forKey: "storeBaseCurrency") ?? "")"
                    ShoppingCartModel.shoppingCartArray[i] = item
                    break
                }
                i = i+1;
            }
            Helper().updateCartPriceAndQty() //update global cart user defaults
            cartItemDelegate?.qtyChanged()
        }
    }
}

class ShoppingCartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwipeTableViewCellDelegate, CartItemTableViewCellDelegate {
    
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var itemsTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shoppingCartView: ShoppingCartView!
    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.dataSource = self
        itemsTableView.delegate = self
        itemsTableView.rowHeight = UITableView.automaticDimension
        itemsTableView.estimatedRowHeight = 65.0
    }
    
    override func viewDidLayoutSubviews() {
        itemsTableView.frame = CGRect(x: itemsTableView.frame.origin.x, y: itemsTableView.frame.origin.y, width: itemsTableView.frame.size.width, height: itemsTableView.contentSize.height)
    }

    override func viewDidAppear(_ animated: Bool) {
        itemsTableView.frame = CGRect(x: itemsTableView.frame.origin.x, y: itemsTableView.frame.origin.y, width: itemsTableView.frame.size.width, height: itemsTableView.contentSize.height)
    }

    override func viewWillAppear(_ animated: Bool) {
        updateCartValues()
    }

    func updateCartValues(){
        let totalPriceInCart = UserDefaults.standard.double(forKey: "totalPriceInCart")
        let totalItemsInCart = UserDefaults.standard.integer(forKey: "totalItemsInCart")
        shoppingCartView.totalPrice.text = "\(totalPriceInCart) \(UserDefaults.standard.string(forKey: "storeBaseCurrency") ?? "")"
        shoppingCartView.totalQty.text = "\(totalItemsInCart)"
        shoppingCartView.viewCartButton.setTitle("Place Your Order", for: .normal)
        shoppingCartView.viewCartButton.addTarget(self, action: Selector(("placeOrderButtonTapped:")), for: .touchUpInside)
    }
    
    @objc func placeOrderButtonTapped(_ sender: UIButton){
        
        var cartItems = [[String]]()
        for item in ShoppingCartModel.shoppingCartArray
        {
            var itemArr = [String]()
            itemArr.append(item.item_id)
            itemArr.append("\(item.qty)")
            cartItems.append(itemArr)
        }
        let urlToPost = "\(Constants.backendServerURLBase)insertOrder.php"
        let addressToPay = UserDefaults.standard.string(forKey: "peopleAddress") ?? ""
        let walletAddress = KeychainWrapper.standard.string(forKey: "walletAddress")!
        let totalPriceInCart = UserDefaults.standard.double(forKey: "totalPriceInCart")
        let currency_id = UserDefaults.standard.string(forKey: "storeBaseCurrencyId") ?? ""
        let uuid = Helper.returnUUID().sha256()
        let parameters = ["address_to_pay": addressToPay, "order_address" : walletAddress, "total": "\(totalPriceInCart)", "currency_id": currency_id, "uuid": uuid, "cart_items": cartItems] as [String : Any]
        
        SVProgressHUD.show()
        Alamofire.request(urlToPost, method: .post, parameters: parameters, headers: nil).responseJSON {
            response in
            switch response.result {
            case .success:
                SVProgressHUD.dismiss()
                let json = JSON(response.result.value)
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "OrderProgressVC") as? OrderProgressAndPaymentViewController {
                    viewController.orderId = "\(json[1])"
                    self.present(viewController, animated: true, completion: nil)
                }
                break
            case .failure( _):
                SVProgressHUD.dismiss()
                let alert = Helper.presentAlert(title: "Error", description: "Could not place order, please try again later!", buttonText: "OK")
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ShoppingCartModel.shoppingCartArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cartItemCell", for: indexPath) as! CartItemTableViewCell
        cell.delegate = self
        cell.cartItemDelegate = self
        cell.tableView = tableView
        cell.indexPath = indexPath
        cell.idOfTheRecord = ShoppingCartModel.shoppingCartArray[indexPath.row].id
        cell.itemNameLabel.text = ShoppingCartModel.shoppingCartArray[indexPath.row].name
        cell.qtyLabel.text = "\(ShoppingCartModel.shoppingCartArray[indexPath.row].qty)"
        var updatedPriceAfterQty = Double(ShoppingCartModel.shoppingCartArray[indexPath.row].qty) * ShoppingCartModel.shoppingCartArray[indexPath.row].price
        updatedPriceAfterQty = round(updatedPriceAfterQty * 1000)/1000
        cell.itemPriceLabel.text = "\(updatedPriceAfterQty) \(UserDefaults.standard.string(forKey: "storeBaseCurrency") ?? "")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // SwipeCell function
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: nil) { action, indexPath in
            self.deleteItem(tableView: tableView, at: indexPath)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete")
        
        return [deleteAction]
    }
    
    func deleteItem (tableView: UITableView, at indexPath: IndexPath){
        let alertMessage = "Delete Item"
        let message = "Do you really want to delete this item from the shopping cart?"
        let alert = UIAlertController(title: alertMessage, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in ShoppingCartModel.shoppingCartArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            tableView.tableFooterView = UIView()
            if ShoppingCartModel.shoppingCartArray.isEmpty {
                self.dismiss(animated: true, completion: nil)
            }
            
            //update the cart
            let helper = Helper()
            helper.updateCartPriceAndQty()
            let totalPriceInCart = UserDefaults.standard.double(forKey: "totalPriceInCart")
            let totalItemsInCart = UserDefaults.standard.integer(forKey: "totalItemsInCart")
            self.shoppingCartView.totalPrice.text = "\(totalPriceInCart) \(UserDefaults.standard.string(forKey: "storeBaseCurrency") ?? "")"
            self.shoppingCartView.totalQty.text = "\(totalItemsInCart)"
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in let cell = tableView.cellForRow(at: indexPath) as! CartItemTableViewCell
            cell.hideSwipe(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showDeleteButtonOnSwipe(tableView: UITableView, at indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! CartItemTableViewCell
        cell.showSwipe(orientation: .right, animated: true)
    }
    
    func qtyChanged(){
        updateCartValues()
    }
    
}

