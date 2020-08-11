//
//  ProductViewController.swift
//  PDFCart
//
//  Created by SOTSYS098 on 07/08/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import UIKit

class ProductViewController: UIViewController {

    let product : ProductDM? = nil
    
    @IBOutlet weak var lblSelectedProduct: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let prod = self.product {
            self.lblSelectedProduct.text = prod.productName
        }
    }
    

}
