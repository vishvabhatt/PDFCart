//
//  ProductDM.swift
//  PDFCart
//
//  Created by SOTSYS098 on 07/08/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import Foundation
import UIKit

struct ProductDM {
    var productName : String = ""
    var productCoords : CGRect = CGRect.zero
    
    init(dict: [String:Any]){
        if let name = dict["p_name"] as? String, let coords = dict["p_coords"] as? [Double] {
            self.productName = name
            self.productCoords = CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
        }
        else{
            print("Watch Out")
            return
        }
    }
}
