//
//	PdfPage.swift
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation
import UIKit

struct PdfPage{

	var pageName : String = ""
    var pageHeight : CGFloat = CGFloat.zero
	var pageWidth : CGFloat = CGFloat.zero
	var arrayProducts : [Product] = []


	/**
	 * Instantiate the instance using the passed dictionary values to set the properties values
	 */
	init(fromDictionary dictionary: [String:Any]){
		pageName = dictionary["pageName"] as? String ?? " "
        pageHeight = dictionary["page_Height"] as? CGFloat ?? CGFloat.zero
		pageWidth = dictionary["page_Width"] as? CGFloat ?? CGFloat.zero
		arrayProducts = [Product]()
		if let productsArray = dictionary["products"] as? [[String:Any]]{
			for dic in productsArray{
				let value = Product(fromDictionary: dic)
				arrayProducts.append(value)
			}
		}
    
	}

	/**
	 * Returns all the available property values in the form of [String:Any] object where the key is the approperiate json key and the value is the value of the corresponding property
	 */
	func toDictionary() -> [String:Any]
	{
		var dictionary = [String:Any]()
		if pageName != nil{
			dictionary["pageName"] = pageName
		}
		if pageHeight != nil{
			dictionary["page_Height"] = pageHeight
		}
		if pageWidth != nil{
			dictionary["page_Width"] = pageWidth
		}
		if arrayProducts != nil{
			var dictionaryElements = [[String:Any]]()
			for productsElement in arrayProducts {
				dictionaryElements.append(productsElement.toDictionary())
			}
			dictionary["products"] = dictionaryElements
		}
		return dictionary
	}

}
