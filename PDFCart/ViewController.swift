//
//  ViewController.swift
//  PDFCart
//
//  Created by Admin1 on 26/06/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import UIKit
import PDFKit
import Toast_Swift


enum ProductFlyer : String {
    case penha_1 = "penha 1"
    case spanishFlyer = "SpanishFlyer"
    case supermarket = "SuperMarket"
    case cosmetic = "Cosmetic"
    case electricProduct = "ElectricProduct"
    case dmart = "DMart"
    case sixPages = "6Pages"
    case dmart1 = "DMart1"
    case diffSize = "DifSize"

    func jsonFileName() -> JSON_Response {
        switch self {
        case .penha_1: return .penha_1
        case .spanishFlyer: return .spanishFlyer
        case .supermarket: return .supermarket
        case .cosmetic:  return .cosmetic
        case .electricProduct: return .electricProduct
        case .dmart: return .dmart
        case .sixPages: return .sixPages
        case .dmart1: return .dmart1
        case .diffSize : return .diffSize
        }
    }
}

enum JSON_Response : String {
    case penha_1 = "penha 1"
    case supermarket = "SuperMarket"
    case spanishFlyer = "SpanishFlyer"
    case cosmetic = "Cosmetic"
    case electricProduct = "ElectronicProducts"
    case dmart = "DMartProducts"
    case sixPages = "6Pages"
    case dmart1 = "DMart1"
    case diffSize = "DifSize"
}
extension ViewController: ThumbnailGridViewControllerDelegate {
    
    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage) {
        self.selectedPage = page
    }
    
    
}
class ViewController: UIViewController,PDFViewDelegate,UIGestureRecognizerDelegate {
    
    //MARK: OBJECTS DECLARATION
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var lblNoData: UILabel!
    
    private var shouldUpdatePDFScrollPosition = true
    var currentlySelectedAnnotation: PDFAnnotation?
    var gesturePDFAnnotationTap = UITapGestureRecognizer()
    var isAnnotationHit = false
    var pdfHeightAtPage : CGFloat = CGFloat.zero
    var pdfWidthAtPage : CGFloat = CGFloat.zero
    var hScale : CGFloat = 1.0
    var wScale : CGFloat = 1.0
    let productFlyer : ProductFlyer = .dmart1
    var currentPage = 0

    var productMaster : ProductMaster!
    weak var delegate: ThumbnailGridViewControllerDelegate?
    
    var selectedPage : PDFPage?

    override func viewDidLoad() {
        super.viewDidLoad()
        lblNoData.text = ""
        self.loadPDF()
        gesturePDFAnnotationTap = UITapGestureRecognizer(target: self, action: #selector(self.singleHandleTap(_:)))
        gesturePDFAnnotationTap.numberOfTapsRequired = 1
        gesturePDFAnnotationTap.delegate = self
        self.pdfView.addGestureRecognizer(gesturePDFAnnotationTap)
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = .black
        ToastManager.shared.style = style
    }
    
    func readJson() {
        self.currentPage = 0
        do {
            let jsonName = self.productFlyer.jsonFileName().rawValue
            if let file = Bundle.main.url(forResource: jsonName, withExtension: "json") {
                let data = try Data(contentsOf: file)
                if let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
                    self.productMaster = ProductMaster(fromDictionary: dict)
                    if productMaster.pdfPages.count == 0 {
                        self.noData(becauseOF: "No product available")
                        
                    }else{
                        if productMaster.pdfPages[currentPage].arrayProducts.count == 0 {
                            self.noData(becauseOF: "No product available")
                        }else{
                            self.pdfView.isHidden = false
                        }
                    }
                }else{
                    self.noData(becauseOF: "No data found")
                }
            } else { self.noData(becauseOF: "No such a file")}
        } catch { print(error.localizedDescription); self.noData(becauseOF: error.localizedDescription) }
    }
    
    func noData(becauseOF:String) {
        self.lblNoData.text = becauseOF
        self.pdfView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // This code is required to fix PDFView Scroll Position when NOT using pdfView.usePageViewController(true)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addPDFNotificationObservers()
        if let selectedPage = self.selectedPage {
            self.pdfView.go(to: selectedPage)

        }
        //self.pdfView.usePageViewController(true, withViewOptions: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removePDFNotificationObservers()
    }
    
    // This code is required to fix PDFView Scroll Position when NOT using pdfView.usePageViewController(true)
    private func fixPDFViewScrollPosition() {
        if let page = pdfView.document?.page(at: 0) {
            pdfView.go(to: PDFDestination(page: page, at: CGPoint(x: 0, y: page.bounds(for: pdfView.displayBox).size.height)))
        }
    }
    
    //MARK: PDF SETUP / LOADING PDF
    func loadPDF() {
        pdfView.displayDirection = .vertical
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.delegate = self
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        self.readJson()
        self.reloadPDF()
        self.addProductViews()
    }
    
    func reloadPDF() {
        if let filePath = self.pdfView.filePath(forKey: self.productFlyer.rawValue) {
            if let document = PDFDocument(url: filePath) {
                pdfView.document = document
            }else{
                guard let path = Bundle.main.url(forResource: self.productFlyer.rawValue, withExtension: "pdf") else {
                    print("file not found")
                    return
                }
                pdfView.document = PDFDocument(url: path)
            }
        }else{
            guard let path = Bundle.main.url(forResource: self.productFlyer.rawValue, withExtension: "pdf") else {
                print("file not found")
                return
            }
            pdfView.document = PDFDocument(url: path)
        }
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        pdfView.sizeToFit()
        pdfView.autoScales = true
        pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
    }
    
    func updateScaleAsPerPage(){
        if let pdfDoc = self.pdfView.document, !pdfView.isHidden {
            if let pdfPage = pdfDoc.page(at: currentPage) {
                let bounds = pdfPage.bounds(for: PDFDisplayBox.cropBox)
                self.hScale = bounds.height/self.productMaster.pdfPages[currentPage].pageHeight
                self.wScale = bounds.width/self.productMaster.pdfPages[currentPage].pageWidth
                self.pdfHeightAtPage = bounds.height
                self.pdfWidthAtPage = bounds.width
            }
        }
    }
    
    func addProductViews() {
        self.updateScaleAsPerPage()
        if !pdfView.isHidden, (self.pdfView.documentView?.viewWithTag(currentPage + 1111)) == nil, let docView = self.pdfView.documentView {
            for product in self.productMaster.pdfPages[currentPage].arrayProducts {
                let y = (self.getYElement() + product.pCoords.origin.y)
                let productC = CGRect(x: product.pCoords.origin.x * wScale, y:  y * hScale, width: product.pCoords.width * wScale, height: product.pCoords.height * hScale)
                let productView = UIView(frame: productC)
                productView.tag = currentPage + 1111
                productView.backgroundColor = UIColor.blue.withAlphaComponent(0.35)
                productView.isUserInteractionEnabled = false
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.0) {
                    docView.addSubview(productView)
                    self.pdfView.layoutDocumentView()
                }
            }
        }
        else if let view = (self.pdfView.documentView?.viewWithTag(currentPage + 1111)) {
            view.isHidden = false
        }
    }
    
    @objc func singleHandleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if isAnnotationHit{
            isAnnotationHit = false
            return
        }
        guard gestureRecognizer.view != nil else { return }
        if gestureRecognizer.state == .ended {
            let touchLocInDoc = gestureRecognizer.location(in: self.pdfView.documentView!)
            //guard let page = self.pdfView.page(for: touchLocInDoc, nearest: true) else {return}
            guard let currentPage = self.pdfView.document?.page(at: currentPage) else {return}
            if let matchedProduct = self.getProduct(point2: touchLocInDoc) {
                let coordinates = matchedProduct.pCoords
                let yf = coordinates.origin.y * self.hScale
                var y = (self.pdfHeightAtPage - yf)
                y = y - (coordinates.height * self.hScale)
                print("Y_Co-ordinate - \(y)")
                let productC = CGRect(x: coordinates.origin.x * wScale, y: y < 0 ? 0 : y , width: coordinates.width * wScale, height: coordinates.height * hScale)
                self.addAnnot(page: currentPage, conver: productC, product: matchedProduct)
            }
        }
    }
    
    
    
    func addAnnot(page:PDFPage, conver:CGRect,product:Product) {
        let pageBounds = page.bounds(for: .cropBox)
        let newAnnotation = PDFAnnotation(bounds: pageBounds, forType: .circle,withProperties:nil)
        newAnnotation.setRect(conver, forAnnotationKey: .rect)
        newAnnotation.color = UIColor.systemYellow.withAlphaComponent(0.8)
        
        let border = PDFBorder()
        border.lineWidth = 20
        border.style = .inset
        newAnnotation.border = border

        UIView.animate(withDuration: 0.5,
                       delay: 1.0,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        page.addAnnotation(newAnnotation)
                    
                        self.view.layoutIfNeeded()
        }, completion: { (finished) -> Void in
            self.showToast(message: "\(product.pName) from page number \(self.productMaster.pdfPages[self.currentPage].pageName) added to cart.")
        })
    }
    
    @IBAction func actionSeeDiscount(_ sender: UISlider) {
        // How to match product discount here - Think
        
        // If slider says 15% discount,
    }
    
    
    func showToast(message: String) {
        self.view.makeToast(message, duration: 0.5, position: .top)
    }
    
    func getYElement(isForMapping:Bool=true) -> CGFloat {
        var muchPlus : CGFloat = .zero
        guard let cPage = self.pdfView.currentPage, let doc = self.pdfView.document else {
            return muchPlus
        }
        let currentPage = doc.index(for: cPage)
        for i in 0..<currentPage {
            muchPlus += self.productMaster.pdfPages[i].pageHeight
        }
        return muchPlus
    }
}


extension ViewController{
    
    //MARK: NOTIFICATION METHOD LISTED..
    
    func addPDFNotificationObservers(){
        NotificationCenter.default.addObserver (self, selector: #selector(handlePageChange), name: Notification.Name.PDFViewPageChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(handleAnnotationHit), name: Notification.Name.PDFViewAnnotationHit, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewDocumentChanged), name: Notification.Name.PDFViewDocumentChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewChangedHistory), name: Notification.Name.PDFViewChangedHistory, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewScaleChanged), name: Notification.Name.PDFViewScaleChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewCopyPermission), name: Notification.Name.PDFViewCopyPermission, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewPrintPermission), name: Notification.Name.PDFViewPrintPermission, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewAnnotationWillHit), name: Notification.Name.PDFViewAnnotationWillHit, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewDisplayModeChanged), name: Notification.Name.PDFViewDisplayModeChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewDisplayBoxChanged), name: Notification.Name.PDFViewDisplayBoxChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewVisiblePagesChanged), name: Notification.Name.PDFViewVisiblePagesChanged, object: nil)
        NotificationCenter.default.addObserver (self, selector: #selector(pdfViewSelectionChanged), name: Notification.Name.PDFViewSelectionChanged, object: nil)
    }
    
    func removePDFNotificationObservers(){
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewPageChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewAnnotationHit, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewDocumentChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewChangedHistory, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewScaleChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewCopyPermission, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewPrintPermission, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewAnnotationWillHit, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewDisplayModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewDisplayBoxChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewVisiblePagesChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.PDFViewSelectionChanged, object: nil)
    }
    
    @objc func handlePageChange() {
        //print("Notification : handlePageChange")
        //print("current page \(pdfView.currentPage!)")
        //print("current page \( String(describing: self.pdfView.document?.index(for: pdfView.currentPage!)))")
        if let doc = self.pdfView.document , let currentPage = self.pdfView.currentPage {
            self.currentPage = doc.index(for: currentPage)
            //self.addProductViews()
        }
        
    }
    
    @objc func pdfViewDocumentChanged() {
        //print("Notification : pdfViewDocumentChanged")
    }
    @objc func pdfViewChangedHistory() {
        //print("Notification : pdfViewChangedHistory")
    }
    @objc func pdfViewScaleChanged() {
        //print("Notification : pdfViewScaleChanged")
    }
    @objc func pdfViewCopyPermission() {
       // print("Notification : pdfViewCopyPermission")
    }
    @objc func pdfViewPrintPermission() {
        //print("Notification : pdfViewPrintPermission")
    }
    @objc func pdfViewDisplayModeChanged() {
        //print("Notification : pdfViewDisplayModeChanged")
    }
    @objc func pdfViewDisplayBoxChanged() {
        //print("Notification : pdfViewDisplayBoxChanged")
    }
    
    @objc func pdfViewVisiblePagesChanged() {
        //print("Notification : pdfViewVisiblePagesChanged")
    }
    
    @objc func handleAnnotationHit(notification : NSNotification) {
        isAnnotationHit = true
        let annotation = notification.userInfo!["PDFAnnotationHit"] as! PDFAnnotation
        self.pdfView.currentPage?.removeAnnotation(annotation)
        self.pdfView.annotationsChanged(on: self.pdfView.currentPage!)
        let testCord = CGPoint(x: annotation.bounds.origin.x, y: self.pdfHeightAtPage - annotation.bounds.origin.y - annotation.bounds.height)
        if let matchedProduct = self.getProductDeSelect(point2: testCord) {
            showToast(message: "\(matchedProduct.pName) removed from cart.")
        }
    }
    
    @objc func pdfViewAnnotationWillHit(notification : NSNotification) {
        print("Notification : pdfViewAnnotationWillHit")
    }
    @objc func pdfViewSelectionChanged(notification : NSNotification.Name) {
        print("Notification : pdfViewSelectionChanged")
    }
    
    func getProduct(point2:CGPoint) -> Product?{
        let products = self.productMaster.pdfPages[currentPage].arrayProducts.indices.filter { (index) -> Bool in
            var compartive = self.productMaster.pdfPages[currentPage].arrayProducts[index].pCoords
            let y = self.getYElement() + compartive.origin.y
            compartive = CGRect(x: compartive.origin.x * wScale, y: y * hScale, width:compartive.width * wScale, height: compartive.height * hScale)
            return compartive.contains(point2)
        }
        if !products.isEmpty, let firstIndex = products.first {
            return self.productMaster.pdfPages[currentPage].arrayProducts[firstIndex]
        }
        return nil
    }
    
    func getProduct(rect2:CGRect) -> Product?{
        /*let products = self.productMaster.arrayProducts.indices.filter { (index) -> Bool in
            var compartive = self.productMaster.arrayProducts[index].productCoords
            compartive = CGRect(x: compartive.origin.x * wScale, y: compartive.origin.y * hScale, width:compartive.width * wScale, height: compartive.height * hScale)
            return compartive.contains(rect2)
        }
        if !products.isEmpty, let firstIndex = products.first {
            return self.productMaster.arrayProducts[firstIndex]
        }*/
        return nil
    }
    
}

extension PDFView{
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                 in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        return documentURL.appendingPathComponent(key + ".pdf")
    }
    
    func store(forKey key: String) {
        if let filePath = filePath(forKey: key) {
            print("File Stored At : \(filePath)")
            self.document?.write(to: filePath)
        }
    }
    
}
extension CGRect{
    func scaled(by scaleFactor: CGFloat) -> CGRect {
        let horizontalInsets = (self.width - (self.width * scaleFactor)) / 2.0
        let verticalInsets = (self.height - (self.height * scaleFactor)) / 2.0
        
        let edgeInsets = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)
        
        let leftOffset = min(self.origin.x + horizontalInsets, 0)
        let upOffset = min(self.origin.y + verticalInsets, 0)

        return self.inset(by: edgeInsets).offsetBy(dx: leftOffset, dy: upOffset)
    }
}
