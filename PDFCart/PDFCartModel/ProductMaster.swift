//
//	ProductMaster.swift
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation

struct ProductMaster{

	var pdfPages : [PdfPage] = []
	var totalPages : Int = 1

	/**
	 * Instantiate the instance using the passed dictionary values to set the properties values
	 */
	init(fromDictionary dictionary: [String:Any]){
		pdfPages = [PdfPage]()
		if let pdfPagesArray = dictionary["pdfPages"] as? [[String:Any]]{
			for dic in pdfPagesArray{
				let value = PdfPage(fromDictionary: dic)
				pdfPages.append(value)
			}
		}
        totalPages = dictionary["totalPages"] as? Int ?? 1
	}

	/**
	 * Returns all the available property values in the form of [String:Any] object where the key is the approperiate json key and the value is the value of the corresponding property
	 */
	func toDictionary() -> [String:Any]
	{
		var dictionary = [String:Any]()
		if pdfPages != nil{
			var dictionaryElements = [[String:Any]]()
			for pdfPagesElement in pdfPages {
				dictionaryElements.append(pdfPagesElement.toDictionary())
			}
			dictionary["pdfPages"] = dictionaryElements
		}
		if totalPages != nil{
			dictionary["totalPages"] = totalPages
		}
		return dictionary
	}

}
