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


let dMart = "Item2"
let electronics = "test"

class ViewController: UIViewController,PDFViewDelegate,UIGestureRecognizerDelegate {
    
    //MARK: OBJECTS DECLARATION
    @IBOutlet weak var pdfView: PDFView!
    
    private var shouldUpdatePDFScrollPosition = true
    var currentlySelectedAnnotation: PDFAnnotation?
    var gesturePDFAnnotationTap = UITapGestureRecognizer()
    var isAnnotationHit = false
    var pdfDocHeight : CGFloat = CGFloat.zero
    var pdfDocWidth : CGFloat = CGFloat.zero
    var hScale : CGFloat = 1.0
    var wScale : CGFloat = 1.0
    var drawingTool = DrawingTool.pen
    let pdfFileName : String = electronics

    var productMaster : ProductMaster!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        do {
            let jsonName = pdfFileName == "test" ? "ElectronicProducts" : "DMartProducts"
            if let file = Bundle.main.url(forResource: jsonName, withExtension: "json") {
                let data = try Data(contentsOf: file)
                if let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
                    self.productMaster = ProductMaster(dict: dict)
                }
            } else { print("No Such a File")}
        } catch { print(error.localizedDescription) }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // This code is required to fix PDFView Scroll Position when NOT using pdfView.usePageViewController(true)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addPDFNotificationObservers()
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
        if let filePath = self.pdfView.filePath(forKey: pdfFileName) {
            if let document = PDFDocument(url: filePath) {
                pdfView.document = document
            }else{
                guard let path = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") else {
                    print("file not found")
                    return
                }
                pdfView.document = PDFDocument(url: path)
            }
        }else{
            guard let path = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") else {
                print("file not found")
                return
            }
            pdfView.document = PDFDocument(url: path)
        }
        pdfView.displayMode = .singlePageContinuous
        pdfView.sizeToFit()
        pdfView.autoScales = true
        pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
        
       if let pdfDoc = self.pdfView.document {
            if let pdfPage = pdfDoc.page(at: 0) {
                let inkAnnotation = PDFAnnotation(bounds: pdfPage.bounds(for: .cropBox), forType: PDFAnnotationSubtype.ink, withProperties: nil)
                self.hScale = inkAnnotation.bounds.height/self.productMaster.pdfHeight
                self.wScale = inkAnnotation.bounds.width/self.productMaster.pdfWidth
                self.pdfDocHeight = inkAnnotation.bounds.height
                self.pdfDocWidth = inkAnnotation.bounds.width
                print("PDFHeight \(self.pdfDocHeight)")
                print("PDFWidth \(self.pdfDocWidth)")
            }
        }
    }
    
    func addProductViews() {
        for product in self.productMaster.arrayProducts {
             let productC = CGRect(x: product.productCoords.origin.x * wScale, y: product.productCoords.origin.y * hScale, width: product.productCoords.width * wScale, height: product.productCoords.height * hScale)
             let productView = UIView(frame: productC)
             productView.backgroundColor = UIColor.blue.withAlphaComponent(0.35)
             productView.isUserInteractionEnabled = false
             self.pdfView.documentView!.addSubview(productView)
         }
         
    }
    
    func convert(_ point: CGPoint, from fromRect: CGRect, to toRect: CGRect) -> CGPoint {
        return CGPoint(x: (toRect.size.width * point.x) / fromRect.size.width, y: (toRect.size.height * point.y) / fromRect.size.height)
    }
    
    func convert(_ point: CGRect, from fromRect: CGRect, to toRect: CGRect) -> CGRect {
        return CGRect(x: (toRect.size.width * point.origin.x) / fromRect.size.width, y: (toRect.size.height * point.origin.y) / fromRect.size.height, width: (toRect.size.width * point.width) / fromRect.size.width,height: (toRect.size.height * point.height) / fromRect.size.height)
    }
    
    private func createFinalAnnotation(area:CGRect, page: PDFPage, color:UIColor) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        let annotation = PDFAnnotation(bounds: area, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        page.addAnnotation(annotation)
        return annotation
    }
    
    @objc func singleHandleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if isAnnotationHit{
            isAnnotationHit = false
            return
        }
        guard gestureRecognizer.view != nil else { return }
        if gestureRecognizer.state == .ended {
            let touchLocInDoc = gestureRecognizer.location(in: self.pdfView.documentView!)
            guard let page = self.pdfView.page(for: touchLocInDoc, nearest: true) else {return}
            if let matchedProduct = self.getProduct(point2: touchLocInDoc) {
                let coordinates = matchedProduct.productCoords
                let yf = coordinates.origin.y * self.hScale
                var y = (self.pdfDocHeight - yf)
                y = y - (coordinates.height * self.hScale)
                let productC = CGRect(x: coordinates.origin.x * wScale, y: y < 0 ? 0 : y , width: coordinates.width * wScale, height: coordinates.height * hScale)
                self.addAnnot(page: page, conver: productC, product: matchedProduct)
            }
        }
    }
    
    func addAnnot(page:PDFPage, conver:CGRect,product:ProductDM) {
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
            self.showToast(message: "\(product.productName) added to cart.")
        })
    }
    
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = UIColor.cyan.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        return annotation
    }
    
    func showToast(message: String) {
        self.view.makeToast(message, duration: 0.5, position: .top)
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
        print("Notification : handlePageChange")
    }
    @objc func pdfViewDocumentChanged() {
        print("Notification : pdfViewDocumentChanged")
    }
    @objc func pdfViewChangedHistory() {
        print("Notification : pdfViewChangedHistory")
    }
    @objc func pdfViewScaleChanged() {
        print("Notification : pdfViewScaleChanged")
    }
    @objc func pdfViewCopyPermission() {
        print("Notification : pdfViewCopyPermission")
    }
    @objc func pdfViewPrintPermission() {
        print("Notification : pdfViewPrintPermission")
    }
    @objc func pdfViewDisplayModeChanged() {
        print("Notification : pdfViewDisplayModeChanged")
    }
    @objc func pdfViewDisplayBoxChanged() {
        print("Notification : pdfViewDisplayBoxChanged")
    }
    @objc func pdfViewVisiblePagesChanged() {
        print("Notification : pdfViewVisiblePagesChanged")
    }
    @objc func handleAnnotationHit(notification : NSNotification) {
        isAnnotationHit = true
        let annotation = notification.userInfo!["PDFAnnotationHit"] as! PDFAnnotation
        self.pdfView.currentPage?.removeAnnotation(annotation)
        self.pdfView.annotationsChanged(on: self.pdfView.currentPage!)
        let testCord = CGPoint(x: annotation.bounds.origin.x, y: self.pdfDocHeight - annotation.bounds.origin.y - annotation.bounds.height)
        if let matchedProduct = self.getProduct(point2: testCord) {
            showToast(message: "\(matchedProduct.productName) removed from cart.")
        }
        
    }
    @objc func pdfViewAnnotationWillHit(notification : NSNotification) {
        print("Notification : pdfViewAnnotationWillHit")
    }
    @objc func pdfViewSelectionChanged(notification : NSNotification.Name) {
        print("Notification : pdfViewSelectionChanged")
    }
    
    func getProduct(point2:CGPoint) -> ProductDM?{
        let products = self.productMaster.arrayProducts.indices.filter { (index) -> Bool in
            var compartive = self.productMaster.arrayProducts[index].productCoords
            compartive = CGRect(x: compartive.origin.x * wScale, y: compartive.origin.y * hScale, width:compartive.width * wScale, height: compartive.height * hScale)
            return compartive.contains(point2)
        }
        if !products.isEmpty, let firstIndex = products.first {
            return self.productMaster.arrayProducts[firstIndex]
        }
        return nil
    }
    
    func getProduct(rect2:CGRect) -> ProductDM?{
        let products = self.productMaster.arrayProducts.indices.filter { (index) -> Bool in
            var compartive = self.productMaster.arrayProducts[index].productCoords
            compartive = CGRect(x: compartive.origin.x * wScale, y: compartive.origin.y * hScale, width:compartive.width * wScale, height: compartive.height * hScale)
            return compartive.contains(rect2)
        }
        if !products.isEmpty, let firstIndex = products.first {
            return self.productMaster.arrayProducts[firstIndex]
        }
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
class DrawingAnnotation: PDFAnnotation {
    public var path = UIBezierPath()
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let pathCopy = path.copy() as! UIBezierPath
        UIGraphicsPushContext(context)
        context.saveGState()
        
        context.setShouldAntialias(true)
        
        color.set()
        pathCopy.lineJoinStyle = .round
        pathCopy.lineCapStyle = .round
        pathCopy.lineWidth = border?.lineWidth ?? 1.0
        pathCopy.stroke()
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}
enum DrawingTool: Int {
    case eraser = 0
    case pencil = 1
    case pen = 2
    case highlighter = 3
    
    var width: CGFloat {
        switch self {
        case .pencil:
            return 1
        case .pen:
            return 5
        case .highlighter:
            return 10
        default:
            return 0
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.3 //0,5
        default:
            return 1
        }
    }
}
