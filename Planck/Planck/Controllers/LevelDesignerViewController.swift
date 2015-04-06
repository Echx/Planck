//
//  LevelDesignerViewController.swift
//  Planck
//
//  Created by NULL on 04/04/15.
//  Copyright (c) 2015年 Echx. All rights reserved.
//

import UIKit
import AVFoundation

class LevelDesignerViewController: UIViewController {

    @IBOutlet var deviceSegment: UISegmentedControl!
    @IBOutlet var inputPanel: UIView!
    @IBOutlet var textFieldCenterX: UITextField!
    @IBOutlet var textFieldCenterY: UITextField!
    @IBOutlet var textFieldCurvatureRadius: UITextField!
    @IBOutlet var textFieldRefractionIndex: UITextField!
    @IBOutlet var textFieldThicknessEdge: UITextField!
    @IBOutlet var textFieldThicknessCenter: UITextField!
    @IBOutlet var textFieldThickness: UITextField!
    @IBOutlet var textFieldDirection: UITextField!
    @IBOutlet var textFieldLength: UITextField!
    
    @IBOutlet var labelCenterX: UILabel!
    @IBOutlet var labelCenterY: UILabel!
    @IBOutlet var labelCurvatureRadius: UILabel!
    @IBOutlet var labelRefractionIndex: UILabel!
    @IBOutlet var labelThicknessEdge: UILabel!
    @IBOutlet var labelThicknessCenter: UILabel!
    @IBOutlet var labelThickness: UILabel!
    @IBOutlet var labelDirection: UILabel!
    @IBOutlet var labelLength: UILabel!
    
    @IBOutlet var planckInputPanel: UIView!
    @IBOutlet var colorPicker: UIPickerView!
    @IBOutlet var notePicker: UIPickerView!
    @IBOutlet var accidentalPicker: UIPickerView!
    @IBOutlet var groupPicker: UIPickerView!
    
    @IBOutlet weak var loadButton: UIBarButtonItem!
    
    var paramenterFields: [UITextField] {
        get {
            return [textFieldCenterX,
                textFieldCenterY,
                textFieldDirection,
                textFieldThickness,
                textFieldThicknessCenter,
                textFieldThicknessEdge,
                textFieldRefractionIndex,
                textFieldCurvatureRadius,
                textFieldLength]
        }
    }
    
    var parameterLabels: [UILabel] {
        get {
            return [labelCenterX, labelCenterY, labelCurvatureRadius,
                labelRefractionIndex, labelThicknessEdge, labelThicknessCenter, labelThickness,
                labelDirection, labelLength]
        }
    }
    
    //store the views we draw the various optic devices
    //key is the id of the instrument
    private var deviceViews = [String: UIView]()
    private var rayLayers = [CAShapeLayer]()
    private var selectedNode: GOOpticRep?
    private var audioPlayerList = [AVAudioPlayer]()
    private var grid: GOGrid
    private var game:GameLevel?
    
    private let identifierLength = 20
    private let gridWidth = 64
    private let gridHeight = 48
    private let gridUnitLength: CGFloat = 16
    
    private let cellID = "Cell"
    private let storyBoardID = "Main"
    private let levelSelectVCID = "DESIGNER_SELECT"
    
    private let validNamePattern = "^[a-zA-Z0-9]+$"
    
    
    struct Selectors {
        static let segmentValueDidChangeAction: Selector = "segmentValueDidChange:"
    }
    
    struct DeviceColor {
        static let mirror = UIColor.whiteColor()
        static let lens = UIColor(red: 190/255.0, green: 1, blue: 1, alpha: 1)
        static let wall = UIColor.blackColor()
        static let planck = UIColor.yellowColor()
        static let emitter = UIColor.greenColor()
    }
    
    struct DeviceSegmentIndex {
        static let emitter = 0;
        static let flatMirror = 1;
        static let flatLens = 2;
        static let flatWall = 3;
        static let concaveLens = 4;
        static let convexLens = 5;
        static let planck = 6;
    }
    
    struct InputTextFieldIndex {
        static let centerX = 0
        static let centerY = 1
        static let direction = 2
        static let thickness = 3
        static let thicknessCenter = 4
        static let thicknessEdge = 5
        static let refractionIndex = 6
        static let curvatureRadius = 7
        static let length = 8
        
    }
    
    struct AlertViewText {
        static let save_title = "Saving current level"
        static let save_msg = "Please enter your level name"
        static let btn_save = "Save"
        static let btn_cancel = "Cancel"
        static let default_text = "untitled"
        static let wrong_title = "Error"
        static let wrong_msg = "The name should not be empty" +
        " or contain any special character."
        static let wrong_confirm = "OK"
    }
    
    struct InputModeSegmentIndex {
        static let add = 0;
        static let edit = 1;
    }
    
    required init(coder aDecoder: NSCoder) {
        self.grid = GOGrid(width: self.gridWidth, height: self.gridHeight, andUnitLength: self.gridUnitLength)
//        grid.delegate = self
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inputPanel.alpha = 0
        self.inputPanel.userInteractionEnabled = false
        self.inputPanel.layer.cornerRadius = 20
        
        self.planckInputPanel.alpha = 0
        self.planckInputPanel.userInteractionEnabled = false
        self.planckInputPanel.layer.cornerRadius = 20
    }
    
    func updateControlPanelValidItems(input: [Bool]) {
        for var i = 0; i < input.count; i++ {
            self.paramenterFields[i].enabled = input[i]
        }
    }
    
    func updateControlPanelAppearence() {
        for var i = 0; i < self.paramenterFields.count; i++ {
            if self.paramenterFields[i].enabled {
                self.paramenterFields[i].layer.borderColor = UIColor.blackColor().CGColor
                self.paramenterFields[i].alpha = 1
                self.parameterLabels[i].textColor = UIColor.blackColor()
                self.parameterLabels[i].alpha = 1
            } else {
                self.paramenterFields[i].layer.borderColor = UIColor.grayColor().CGColor
                self.paramenterFields[i].alpha = 0.5
                self.parameterLabels[i].textColor = UIColor.grayColor()
                self.parameterLabels[i].alpha = 0.5
            }
        }
    }
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        self.shootRay()
    }
    
    //MARK - tap gesture handler
    @IBAction func viewDidTapped(sender: UITapGestureRecognizer) {
        if sender.numberOfTapsRequired == 1 {
            if sender.numberOfTouchesRequired == 2 {
                if ((self.selectedNode != nil) && (self.selectedNode!.isKindOfClass(XPlanck))) {
                    if self.inputPanel.userInteractionEnabled {
                       self.toggleInputPanel()
                    }
                    self.togglePlanckInputPanel()
                } else {
                    if self.planckInputPanel.userInteractionEnabled {
                        self.togglePlanckInputPanel()
                    }
                    self.toggleInputPanel()
                }
                return
            }
            
            if self.selectedNode != nil {
                self.deselectNode()
            } else {
                let location = sender.locationInView(sender.view)
                self.deselectNode()
                self.selectNode(self.grid.getInstrumentAtPoint(location))
            }
            return
        }

        
        let location = sender.locationInView(sender.view)
        let coordinate = self.grid.getGridCoordinateForPoint(location)
        
        switch(self.deviceSegment.selectedSegmentIndex) {
        case DeviceSegmentIndex.emitter:
            let emitter = GOEmitterRep(center: coordinate, thickness: 2, length: 2, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addNode(emitter, strokeColor: DeviceColor.emitter)
            
        case DeviceSegmentIndex.flatMirror:
            let mirror = XFlatMirror(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addNode(mirror, strokeColor: DeviceColor.mirror)
            
        case DeviceSegmentIndex.flatLens:
            let flatLens = GOFlatLensRep(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), refractionIndex: 1.5, id: String.generateRandomString(self.identifierLength))
            self.addNode(flatLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.flatWall:
            let wall = XWall(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addNode(wall, strokeColor: DeviceColor.wall)
            
        case DeviceSegmentIndex.concaveLens:
            let concaveLens = XConcaveLens(center: coordinate, direction: CGVectorMake(0, 1), thicknessCenter: 1, thicknessEdge: 3, curvatureRadius: 10, id: String.generateRandomString(self.identifierLength), refractionIndex: 1.5)
            self.addNode(concaveLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.convexLens:
            let convexLens = XConvexLens(center: coordinate, direction: CGVectorMake(0, 1), thickness: 2, curvatureRadius: 10, id: String.generateRandomString(self.identifierLength), refractionIndex: 1.5)
            self.addNode(convexLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.planck:
            let planck = XPlanck(center: coordinate, thickness: 6, length: 6, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addNode(planck, strokeColor: DeviceColor.planck)
            
        default:
            fatalError("SegmentNotRecognized")
        }
        self.shootRay()
    }
    
    //MARK - pan gesture handler
    private var firstLocation: CGPoint?
    private var lastLocation: CGPoint?
    private var firstViewCenter: CGPoint?
    private var firstViewTransform: CATransform3D?
    private var touchedNode: GOOpticRep?
    @IBAction func viewDidPanned(sender: UIPanGestureRecognizer) {
        let location = sender.locationInView(self.view)
        
        if let node = self.selectedNode {
            let view = self.deviceViews[node.id]!
            if sender.state == UIGestureRecognizerState.Began {
                firstLocation = location
                lastLocation = location
                firstViewTransform = view.layer.transform
            } else {
                let startVector = CGVectorMake(firstLocation!.x - self.grid.getCenterForGridCell(node.center).x,
                                               firstLocation!.y - self.grid.getCenterForGridCell(node.center).y)
                let currentVector = CGVectorMake(location.x - self.grid.getCenterForGridCell(node.center).x,
                                                 location.y - self.grid.getCenterForGridCell(node.center).y)
                var angle = CGVector.angleFrom(startVector, to: currentVector)
                if sender.state == UIGestureRecognizerState.Ended {
                    let nodeAngle = node.direction.angleFromXPlus
                    let effectAngle = angle + nodeAngle
                    let count = round(effectAngle / self.grid.unitDegree)
                    let finalAngle = self.grid.unitDegree * count
                    angle = finalAngle - nodeAngle
                    node.setDirection(CGVector.vectorFromXPlusRadius(finalAngle))
                }
                var layerTransform = CATransform3DRotate(firstViewTransform!, angle, 0, 0, 1)
                view.layer.transform = layerTransform
            }
        } else {
            if sender.state == UIGestureRecognizerState.Began || touchedNode == nil {
                firstLocation = location
                lastLocation = location
                touchedNode = self.grid.getInstrumentAtPoint(location)
                if let node = touchedNode {
                    firstViewCenter = self.deviceViews[node.id]!.center
                    self.clearRay()
                }
            }
            
            if let node = touchedNode {
                let view = self.deviceViews[node.id]!
                view.center = CGPointMake(view.center.x + location.x - lastLocation!.x, view.center.y + location.y - lastLocation!.y)
                lastLocation = location
                if sender.state == UIGestureRecognizerState.Ended {
                    
                    let offset = CGPointMake(location.x - firstLocation!.x, location.y - firstLocation!.y)
                    
                    self.moveNode(node, from: firstViewCenter!, offset: offset)
                    
                    lastLocation = nil
                    firstLocation = nil
                    firstViewCenter = nil
                }
            }
        }
        
        if sender.state == UIGestureRecognizerState.Ended {
            self.updateTextFieldInformation()
            self.shootRay()
        }
    }
    

    
    
    //MARK - long press gesture handler
    @IBAction func viewDidLongPressed(sender: UILongPressGestureRecognizer) {
        let location = sender.locationInView(sender.view)
        if let node = self.grid.getInstrumentAtPoint(location) {
            self.updateTextFieldInformation()
            self.removeNode(node)
        }
    }
    
    //MARK - bar button handler
    @IBAction func clearButtonDidClicked(sender: UIBarButtonItem) {
        self.grid.clearInstruments()
        for (id, view) in self.deviceViews {
            view.removeFromSuperview()
        }
        
        self.clearRay()
        self.updateTextFieldInformation()
    }
    
    @IBAction func updateSelectedNode() {
        if let node = self.selectedNode {
            self.updateThicknessFromInput()
            self.updateLengthFromInput()
            self.updateCenterFromInput()
            self.updateDirectionFromInput()
            self.updateRefractionIndexFromInput()
            self.updateCurvatureRadiusFromInput()
            
            self.refreshSelectedNode()
        }
        
        
        self.shootRay()
    }
    
    @IBAction func saveButtonDidClicked(sender: AnyObject) {
        self.showSavePrompt()
    }

    @IBAction func loadButtonDidClicked(sender: AnyObject) {
        // Create a level select VC instance
        var storyBoard = UIStoryboard(name: storyBoardID, bundle: nil)
        var levelVC = storyBoard.instantiateViewControllerWithIdentifier(levelSelectVCID)
            as DesignerLevelSelectViewController
        levelVC.modalPresentationStyle = UIModalPresentationStyle.Popover
        levelVC.delegate = self
        self.presentViewController(levelVC, animated: true, completion: nil)
        levelVC.popoverPresentationController?.barButtonItem = self.loadButton
    }
    
    
    
//------------------------------------------------------------------------------
//    Private Methods
//------------------------------------------------------------------------------
    private func refreshSelectedNode() {
        if let node = self.selectedNode {
            if var view = self.deviceViews[node.id] {
                view.removeFromSuperview()
                self.addNode(node, strokeColor: self.getColorForNode(node))
            }
            self.deselectNode()
            self.selectNode(node)
        }
    }
    
    private func updateCurvatureRadiusFromInput() {
        if let node = self.selectedNode {
            if let lens = node as? GOConcaveLensRep {
                let r: CGFloat? = CGFloat((self.textFieldCurvatureRadius.text as NSString).floatValue)
                if let curvatureRadius = r {
                    if curvatureRadius > 0 && curvatureRadius < CGFloat(self.grid.width) && curvatureRadius < CGFloat(self.grid.width) {
                        lens.curvatureRadius = curvatureRadius
                    }
                }
            }
   
            if let lens = node as? GOConvexLensRep {
                let r: CGFloat? = CGFloat((self.textFieldCurvatureRadius.text as NSString).floatValue)
                if let curvatureRadius = r {
                    if curvatureRadius > 0 && curvatureRadius < CGFloat(self.grid.width) && curvatureRadius < CGFloat(self.grid.width) {
                        lens.curvatureRadius = curvatureRadius
                    }
                }
            }
        }
    }
    
    private func updateRefractionIndexFromInput() {
        if let node = self.selectedNode {
            if let lens = node as? GOConcaveLensRep {
                let i: CGFloat? = CGFloat((self.textFieldRefractionIndex.text as NSString).floatValue)
                if let refractionIndex = i {
                    if refractionIndex > 0 && refractionIndex < CGFloat(self.grid.width) && refractionIndex < CGFloat(self.grid.width) {
                        lens.refractionIndex = refractionIndex
                    }
                }
            }
            
            if let lens = node as? GOFlatLensRep {
                let i: CGFloat? = CGFloat((self.textFieldRefractionIndex.text as NSString).floatValue)
                if let refractionIndex = i {
                    if refractionIndex > 0 && refractionIndex < CGFloat(self.grid.width) && refractionIndex < CGFloat(self.grid.width) {
                        lens.refractionIndex = refractionIndex
                    }
                }
            }
            
            if let lens = node as? GOConvexLensRep {
                let i: CGFloat? = CGFloat((self.textFieldRefractionIndex.text as NSString).floatValue)
                if let refractionIndex = i {
                    if refractionIndex > 0 && refractionIndex < CGFloat(self.grid.width) && refractionIndex < CGFloat(self.grid.width) {
                        lens.refractionIndex = refractionIndex
                    }
                }
            }
        }
    }
    
    private func updateLengthFromInput() {
        if let node = self.selectedNode {
            if let flatNode = node as? GOFlatOpticRep {
                let l: CGFloat? = CGFloat((self.textFieldLength.text as NSString).floatValue)
                if let length = l {
                    if length > 0 && length < CGFloat(self.grid.width) && length < CGFloat(self.grid.width) {
                        flatNode.length = length
                    }
                }
            }
        }
    }
    
    private func updateThicknessFromInput() {
        if let node = self.selectedNode {
            let f: CGFloat? = CGFloat((self.textFieldThickness.text as NSString).floatValue)
            let fc: CGFloat? = CGFloat((self.textFieldThicknessCenter.text as NSString).floatValue)
            let fe: CGFloat? = CGFloat((self.textFieldThicknessEdge.text as NSString).floatValue)
            
            if let flatNode = node as? GOFlatOpticRep {
                if let thickness = f {
                    if thickness > 0 && thickness < CGFloat(self.grid.width) && thickness < CGFloat(self.grid.height) {
                        flatNode.thickness = thickness
                    }
                }
            }
            
            if let convexNode = node as? GOConvexLensRep {
                if let thickness = f {
                    if thickness > 0 && thickness < CGFloat(self.grid.width) && thickness < CGFloat(self.grid.height) {
                        convexNode.thickness = thickness
                    }
                }

            }
            
            if let concaveNode = node as? GOConcaveLensRep {
                if let thicknessCenter = fc {
                    if let thicknessEdge = fe {
                        if thicknessCenter < thicknessEdge &&
                            thicknessCenter > 0 &&
                            thicknessEdge < CGFloat(self.grid.width) &&
                            thicknessEdge < CGFloat(self.grid.height) {
                                concaveNode.thicknessEdge = thicknessEdge
                                concaveNode.thicknessCenter = thicknessCenter
                        }
                    }
                }
            }
            let view = self.deviceViews[node.id]
        }
    }
    
    private func updateCenterFromInput() {
        if let node = self.selectedNode {
            let x: Int? = self.textFieldCenterX.text.toInt()
            let y: Int? = self.textFieldCenterY.text.toInt()
            
            if x != nil && y != nil {
                if x! >= 0 && x! <= self.grid.width && y! >= 0 && y! <= self.grid.height {
                    node.center = GOCoordinate(x: x!, y: y!)
                }
            }
        }
    }
    
    private func updateDirectionFromInput() {
        if let node = self.selectedNode {
            let i: Int? = self.textFieldDirection.text.toInt()
            if let index = i {
                let originalDirection = node.direction
                let effectDirection = CGVector.vectorFromXPlusRadius(CGFloat(index) * self.grid.unitDegree)
//                self.updateDirection(node, startVector: originalDirection, currentVector: effectDirection)
                node.direction = effectDirection
            }
        }
    }
    
    private func updateDirection(node: GOOpticRep, startVector: CGVector, currentVector: CGVector) {
        var angle = CGVector.angleFrom(startVector, to: currentVector)
        let nodeAngle = node.direction.angleFromXPlus
        let effectAngle = angle + nodeAngle
        let count = round(effectAngle / self.grid.unitDegree)
        let finalAngle = self.grid.unitDegree * count
        angle = finalAngle - nodeAngle
        node.setDirection(CGVector.vectorFromXPlusRadius(finalAngle))
        if let view = self.deviceViews[node.id] {
            var layerTransform = CATransform3DRotate(view.layer.transform, angle, 0, 0, 1)
            view.layer.transform = layerTransform
        }
    }
    
    private func toggleInputPanel() {
        if self.inputPanel.userInteractionEnabled {
            self.inputPanel.userInteractionEnabled = false
            self.inputPanel.alpha = 0
        } else {
            self.inputPanel.userInteractionEnabled = true
            self.inputPanel.alpha = 0.9
        }
    }
    
    private func togglePlanckInputPanel() {
        if self.planckInputPanel.userInteractionEnabled {
            self.planckInputPanel.userInteractionEnabled = false
            self.planckInputPanel.alpha = 0
        } else {
            self.planckInputPanel.userInteractionEnabled = true
            self.planckInputPanel.alpha = 0.9
        }
    }
    
    private func updateTextFieldInformation() {
        if let node = self.selectedNode {
            self.textFieldCenterX.text = "\(node.center.x)"
            self.textFieldCenterY.text = "\(node.center.y)"
            self.textFieldDirection.text = "\(Int(round(node.direction.angleFromXPlus / self.grid.unitDegree)))"
            
            if let flatNode = node as? GOFlatOpticRep {
                self.textFieldThickness.text = "\(flatNode.thickness)"
                self.textFieldLength.text = "\(flatNode.length)"
                
                if let flatLens = flatNode as? GOFlatLensRep {
                    self.textFieldRefractionIndex.text = "\(flatLens.refractionIndex)"
                } else {
                    self.textFieldRefractionIndex.text = ""
                }
                self.textFieldThicknessCenter.text = ""
                self.textFieldThicknessEdge.text = ""
                self.textFieldCurvatureRadius.text = ""
            } else if let concaveLens = node as? GOConcaveLensRep {
                self.textFieldThicknessCenter.text = "\(concaveLens.thicknessCenter)"
                self.textFieldThicknessEdge.text = "\(concaveLens.thicknessEdge)"
                self.textFieldRefractionIndex.text = "\(concaveLens.refractionIndex)"
                self.textFieldCurvatureRadius.text = "\(concaveLens.curvatureRadius)"
                self.textFieldThickness.text = ""
                self.textFieldLength.text = ""
            } else if let convexLens = node as? GOConvexLensRep {
                self.textFieldThickness.text = "\(convexLens.thickness)"
                self.textFieldRefractionIndex.text = "\(convexLens.refractionIndex)"
                self.textFieldCurvatureRadius.text = "\(convexLens.curvatureRadius)"
                self.textFieldThicknessCenter.text = ""
                self.textFieldThicknessEdge.text = ""
                self.textFieldLength.text = ""
            }
            
            var input = [Bool]()
            
            if let device = node as? GOEmitterRep {
                input = [true, true, true, true, false, false, false, false, true]
            }
            
            if let device = node as? GOFlatMirrorRep {
                input = [true, true, true, true, false, false, false, false, true]
            }
            
            if let device = node as? GOFlatWallRep {
                input = [true, true, true, true, false, false, false, false, true]
            }
            
            if let device = node as? GOFlatLensRep {
                input = [true, true, true, false, false, false, true, false, true]
            }
            
            if let device = node as? GOConcaveLensRep {
                input = [true, true, true, false, true, true, true, true, false]
            }
            
            if let device = node as? GOConvexLensRep {
                input = [true, true, true, true, false, false, true, true, false]
            }
            
            self.updateControlPanelValidItems(input)
        } else {
            self.textFieldCenterX.text = ""
            self.textFieldCenterY.text = ""
            self.textFieldDirection.text = ""
            self.textFieldThickness.text = ""
            self.textFieldRefractionIndex.text = ""
            self.textFieldCurvatureRadius.text = ""
            self.textFieldThicknessCenter.text = ""
            self.textFieldThicknessEdge.text = ""
            self.textFieldLength.text = ""
        }
    }
    
    private func selectNode(optionalNode: GOOpticRep?) {
        if let node = optionalNode {
            self.selectedNode = node
            if let view = self.deviceViews[node.id] {
                view.alpha = 0.5
            }
        } else {
            self.deselectNode()
        }
        
        self.updateTextFieldInformation()
    }
    
    private func deselectNode() {
        if let node = self.selectedNode {
            if let view = self.deviceViews[node.id] {
                view.alpha = 1
            }
        }
        self.selectedNode = nil
        self.updateTextFieldInformation()
    }
    
    private func addNode(node: GOOpticRep, strokeColor: UIColor) {
        self.clearRay()
        var coordinateBackup = node.center
        node.setCenter(GOCoordinate(x: self.grid.width/2, y: self.grid.height/2))
        
        self.grid.addInstrument(node)
        let layer = CAShapeLayer()
        layer.strokeEnd = 1.0
        layer.strokeColor = strokeColor.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 2.0
        layer.path = self.grid.getInstrumentDisplayPathForID(node.id)?.CGPath
        
        let view = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        view.backgroundColor = UIColor.clearColor()
        view.layer.addSublayer(layer)
        self.deviceViews[node.id] = view
        self.view.insertSubview(view, atIndex: 0)
        
        var offsetX = CGFloat(coordinateBackup.x - node.center.x) * self.grid.unitLength
        var offsetY = CGFloat(coordinateBackup.y - node.center.y) * self.grid.unitLength
        var offset = CGPointMake(offsetX, offsetY)
        
        self.moveNode(node, from: self.view.center, offset: offset)
    }

    
    private func moveNode(node: GOOpticRep, from: CGPoint,offset: CGPoint) {
        let offsetX = offset.x
        let offsetY = offset.y
        
        let originalDisplayPoint = self.grid.getCenterForGridCell(node.center)
        let effectDisplayPoint = CGPointMake(originalDisplayPoint.x + offsetX, originalDisplayPoint.y + offsetY)
        
        node.setCenter(self.grid.getGridCoordinateForPoint(effectDisplayPoint))
        
        let view = self.deviceViews[node.id]!
        let finalDisplayPoint = self.grid.getCenterForGridCell(node.center)
        let finalX = finalDisplayPoint.x - originalDisplayPoint.x + from.x
        let finalY = finalDisplayPoint.y - originalDisplayPoint.y + from.y
        
        view.center = CGPointMake(finalX, finalY)
    }
    
    private func moveNode(node: GOOpticRep, to: GOCoordinate) {
        let originalCenter = self.grid.getCenterForGridCell(node.center)
        let finalCenter = self.grid.getCenterForGridCell(to)
        let offsetX = finalCenter.x - originalCenter.x
        let offsetY = finalCenter.y - originalCenter.y
        let offset = CGPointMake(offsetX, offsetY)
        self.moveNode(node, from: originalCenter, offset: offset)
    }

    private func removeNode(node: GOOpticRep) {
        self.deviceViews[node.id]?.removeFromSuperview()
        self.deviceViews[node.id] = nil
        self.grid.removeInstrumentForID(node.id)
        self.shootRay()
    }
    
    private func addRay(point: CGPoint) {
        let ray = GORay(startPoint: self.grid.getGridPointForDisplayPoint(point), direction: CGVector(dx: 1, dy: 0))
        let layer = CAShapeLayer()
        layer.strokeEnd = 1.0
        layer.strokeColor = UIColor.whiteColor().CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 2.0
        
        self.rayLayers.append(layer)
        
        let goPath = self.grid.getRayPath(ray)
        let path = goPath.bezierPath
        let points = goPath.criticalPoints
        let distance = goPath.pathLength
        self.processPoints(points)
        layer.path = path.CGPath
        self.view.layer.addSublayer(layer)
        
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.fromValue = 0.0;
        pathAnimation.toValue = 1.0;
        pathAnimation.duration = CFTimeInterval(distance / Constant.lightSpeedBase);
        pathAnimation.repeatCount = 1.0
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        layer.addAnimation(pathAnimation, forKey: "strokeEnd")
    }
    
    private func shootRay() {
        self.clearRay()
        for (name, item) in self.grid.instruments {
            if item.type == DeviceType.Emitter {
                let coordinate = (item as GOEmitterRep).center
                let shootingCoordinate = GOCoordinate(x: coordinate.x + 1, y: coordinate.y)
                let shootingPoint = self.grid.getPointForGridCoordinate(shootingCoordinate)
                self.addRay(shootingPoint)
            }
            
        }
    }
    
    private func clearRay() {
        for layer in self.rayLayers {
            layer.removeFromSuperlayer()
        }
        self.audioPlayerList.removeAll(keepCapacity: false)
    }
    
    private func getColorForNode(node: GOOpticRep) -> UIColor {
        switch node.type {
        case .Emitter:
            return DeviceColor.emitter
        case .Lens:
            return DeviceColor.lens
        case .Mirror:
            return DeviceColor.mirror
        case .Wall:
            return DeviceColor.planck
            
        default:
            return UIColor.whiteColor()
        }
    }
    
    private func processPoints(points: [CGPoint]) {
        if points.count > 2 {
            var prevPoint = points[0]
            var distance: CGFloat = 0
            for i in 1...points.count - 1 {
                distance += points[i].getDistanceToPoint(prevPoint)
                prevPoint = points[i]
                if let device = self.grid.getInstrumentAtGridPoint(points[i]) {
                    if let sound = device.getSound() {
                        let audioPlayer = AVAudioPlayer(contentsOfURL: sound, error: nil)
                        self.audioPlayerList.append(audioPlayer)
                        audioPlayer.prepareToPlay()
                        let wait = NSTimeInterval(distance / Constant.lightSpeedBase + Constant.audioDelay)
                        audioPlayer.playAtTime(wait + audioPlayer.deviceCurrentTime)
                    }
                }
            }
        }
    }
    
    private func loadLevel(level:GameLevel) {
        self.grid.clearInstruments()
        for (id, view) in self.deviceViews {
            view.removeFromSuperview()
        }
        self.clearRay()
        
        for (id, opticNode) in level.grid.instruments {
            self.addNode(opticNode, strokeColor: getColorForNode(opticNode))
        }
        
        self.shootRay()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - ALERT
    private func showSavePrompt() {
        // 1.Initialze an alert
        var alert = UIAlertController(title: AlertViewText.save_title, message: AlertViewText.save_msg, preferredStyle: .Alert)
        
        // 2. Add the text field
        alert.addTextFieldWithConfigurationHandler{ (textField) in
            if let currentLevel = self.game {
                textField.text = currentLevel.name
            } else {
                textField.text = AlertViewText.default_text
            }
        }
        
        //3. Set up button and its handler
        alert.addAction(UIAlertAction(title: AlertViewText.btn_save, style: .Default,
            handler: { action in
                let textField = alert.textFields![0] as UITextField
                // validate textField input (non-empty)
                let whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet
                let inputName = textField.text.stringByTrimmingCharactersInSet(whitespace())
                
                let regEx = NSRegularExpression(pattern: self.validNamePattern,
                    options: nil,
                    error: nil)!
                
                if let match = regEx.firstMatchInString(inputName, options: nil,
                    range: NSRange(location: 0, length: inputName.utf16Count)) {
                        // valid
                        let game = GameLevel(levelName: inputName, levelIndex: 1, grid: self.grid)
                        self.game = game
                    StorageManager.defaultManager.saveCurrentLevel(game)
                } else {
                    // invalid
                    self.showWrongInputAlert()
                }
        }))
        
        alert.addAction(UIAlertAction(title: AlertViewText.btn_cancel,
            style: UIAlertActionStyle.Cancel, handler: nil))
        
        // 4. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showWrongInputAlert() {
        // 1.Initialze an alert
        var alert = UIAlertController(title: AlertViewText.wrong_title,
            message: AlertViewText.wrong_msg,
            preferredStyle: .Alert)
        
        // 2. Set up button and its handler
        alert.addAction(UIAlertAction(title: AlertViewText.wrong_confirm, style: .Cancel,
            handler: { action in
                self.showSavePrompt()
        }))
        
        // 3. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)
    }

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LevelDesignerViewController:LevelSelectDelegate {
    func loadSelectLevel(level:GameLevel) {
        self.dismissViewControllerAnimated(true, completion: {
            self.loadLevel(level)
            self.game = level
        })
        
    }
}
