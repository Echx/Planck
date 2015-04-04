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
    
    //store the layer we draw the various optic devices
    //key is the id of the instrument
    var deviceLayers = [String: CAShapeLayer]()
    var rayLayers = [CAShapeLayer]()
    
    let grid: GOGrid
    let identifierLength = 20;
    required init(coder aDecoder: NSCoder) {
        self.grid = GOGrid(width: 128, height: 96, andUnitLength: 8)
        super.init(coder: aDecoder)
    }
    
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
    
    struct InputModeSegmentIndex {
        static let add = 0;
        static let edit = 1;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func addInstrument(instrument: GOOpticRep, strokeColor: UIColor) {
        self.clearRay()
        self.grid.addInstrument(instrument)
        let layer = CAShapeLayer()
        layer.strokeEnd = 1.0
        layer.strokeColor = strokeColor.CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 2.0
        self.deviceLayers[instrument.id] = layer
        layer.path = self.grid.getInstrumentDisplayPathForID(instrument.id)?.CGPath
        self.view.layer.addSublayer(layer)
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
        for (name, item) in self.grid.instruments {
            if item.type == DeviceType.Emitter {
                let coordinate = (item as GOEmitterRep).center
                let shootingCoordinate = GOCoordinate(x: coordinate.x + 1, y: coordinate.y)
                let shootingPoint = self.grid.getPointForGridCoordinate(shootingCoordinate)
                self.addRay(shootingPoint)
            }
            
        }
    }
    
    //MARK - tap gesture handler
    @IBAction func viewDidTapped(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(sender.view)
        let coordinate = self.grid.getGridCoordinateForPoint(location)
        
        switch(self.deviceSegment.selectedSegmentIndex) {
        case DeviceSegmentIndex.emitter:
            let emitter = GOEmitterRep(center: coordinate, thickness: 2, length: 2, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addInstrument(emitter, strokeColor: DeviceColor.emitter)
            
        case DeviceSegmentIndex.flatMirror:
            let mirror = GOFlatMirrorRep(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addInstrument(mirror, strokeColor: DeviceColor.mirror)
            
            println("contains point: \(mirror.containsPoint(CGPointMake(CGFloat(mirror.center.x), CGFloat(mirror.center.y))))")
            
            
        case DeviceSegmentIndex.flatLens:
            let flatLens = GOFlatLensRep(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), refractionIndex: 1.5, id: String.generateRandomString(self.identifierLength))
            self.addInstrument(flatLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.flatWall:
            let wall = GOFlatWallRep(center: coordinate, thickness: 2, length: 8, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addInstrument(wall, strokeColor: DeviceColor.wall)
            
        case DeviceSegmentIndex.concaveLens:
            let concaveLens = GOConcaveLensRep(center: coordinate, direction: CGVectorMake(0, 1), thicknessCenter: 1, thicknessEdge: 3, curvatureRadius: 10, id: String.generateRandomString(self.identifierLength), refractionIndex: 1.5)
            self.addInstrument(concaveLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.convexLens:
            let convexLens = GOConvexLensRep(center: coordinate, direction: CGVectorMake(0, 1), thickness: 2, curvatureRadius: 10, id: String.generateRandomString(self.identifierLength), refractionIndex: 1.5)
            self.addInstrument(convexLens, strokeColor: DeviceColor.lens)
            
        case DeviceSegmentIndex.planck:
            let planck = GOFlatWallRep(center: coordinate, thickness: 6, length: 6, direction: CGVectorMake(0, 1), id: String.generateRandomString(self.identifierLength))
            self.addInstrument(planck, strokeColor: DeviceColor.planck)
            
        default:
            fatalError("SegmentNotRecognized")
        }
        self.shootRay()
    }
    
    //MARK - pan gesture handler
    @IBAction func viewDidPanned(sender: UIPanGestureRecognizer) {
        let location = sender.locationInView(sender.view)
        let instrument = self.grid.getInstrumentAtPoint(location)
        println(instrument)
    }
    
    
    @IBAction func viewDidLongPressed(sender: UILongPressGestureRecognizer) {
        println("longPressed")
    }
    
    @IBAction func clearButtonDidClicked(sender: UIBarButtonItem) {
        self.grid.clearInstruments()
        for (id, layer) in self.deviceLayers {
            layer.removeFromSuperlayer()
        }
        self.clearRay()
    }
    
    private func clearRay() {
        for layer in self.rayLayers {
            layer.removeFromSuperlayer()
        }
    }
    
    private func processPoints(points: [CGPoint]) {
        var bounceSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("cymbal", ofType: "m4a")!)
        for point in points {
            if let device = self.grid.getInstrumentAtPoint(point) {
                switch device.type {
                case DeviceType.Mirror :
                    let audioPlayer = AVAudioPlayer(contentsOfURL: bounceSound, error: nil)
                    audioPlayer.prepareToPlay()
                    audioPlayer.play()
                default :
                    1
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
