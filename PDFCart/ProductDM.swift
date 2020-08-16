//
//  ProductDM.swift
//  PDFCart
//
//  Created by SOTSYS098 on 07/08/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import Foundation
import UIKit

struct ProductMaster {
    var pdfHeight : CGFloat = CGFloat.zero
    var pdfWidth : CGFloat = CGFloat.zero
    var arrayProducts : [ProductDM] = []
    
    init(dict : [String:Any]) {
        if let height = dict["pdfHeight"] as? Double, let width = dict["pdfWidth"] as? Double, let products = dict["products"] as? [[String:Any]] {
            self.pdfWidth = CGFloat(width)
            self.pdfHeight = CGFloat(height)
            for i in products {
                self.arrayProducts.append(ProductDM(dict: i))
            }
        }else{
            print("Watch Out-ProductMaster")
            return
        }
    }
    
    /*init(dict: [String:Any]){
        if let name = dict["p_name"] as? String, let coords = dict["p_coords"] as? [Double] {
            self.productName = name
            self.productCoords = CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
        }
        else{
            print("Watch Out")
            return
        }
    }*/
    
}

struct ProductDM {
    var productName : String = ""
    var productCoords : CGRect = CGRect.zero
    
    init(dict: [String:Any]){
        if let name = dict["p_name"] as? String, let coords = dict["p_coords"] as? [Double] {
            self.productName = name
            self.productCoords = CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
        }
        else{
            print("Watch Out - ProductDM")
            return
        }
    }
}
