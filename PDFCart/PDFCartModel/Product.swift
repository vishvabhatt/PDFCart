//
//	Product.swift
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation
import UIKit

struct Product{

    var pCoords : CGRect = CGRect.zero
	var pName : String = ""

	/**
	 * Instantiate the instance using the passed dictionary values to set the properties values
	 */
    init(fromDictionary dictionary: [String:Any]){
        if let name = dictionary["p_name"] as? String, let coords = dictionary["p_coords"] as? [Double] {
            self.pName = name
            self.pCoords = CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
        }
        else{
            print("Watch Out - Product")
            return
        }
    }

	/**
	 * Returns all the available property values in the form of [String:Any] object where the key is the approperiate json key and the value is the value of the corresponding property
	 */
	func toDictionary() -> [String:Any]
	{
		var dictionary = [String:Any]()
        dictionary["p_coords"] = pCoords
        dictionary["p_name"] = pName
        return dictionary
	}

}
