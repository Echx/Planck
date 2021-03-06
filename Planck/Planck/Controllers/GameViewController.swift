//
//  GameViewController.swift
//  Planck
//
//  Created by Wang Jinghan on 07/04/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit

// this is the main controller controlling the game play, handling the 
// interaction between the game engine and the player
class GameViewController: XViewController {
    var gameLevel: GameLevel = GameLevel()
    // keep a copy of original level
    private var originalLevel: GameLevel = GameLevel()
    private var rayLayers = [String: [CAShapeLayer]]()
    private var rays = [String: [(CGPoint, GOSegment?)]]()
    private var audioPlayerList = [AVAudioPlayer]()
    private var music = XMusic()
    private var pathDistances = [String: CGFloat]()
    private var visitedPlanckList = [XNode]()
    private var visitedNoteList = [XNote]()
    private var emitterLayers = [String: [CAEmitterLayer]]()
    private var deviceViews = [String: UIView]()
    private var transitionMask = LevelTransitionMaskView()
    private var pauseMask = PauseMaskView()
    private var musicMask = TargetMusicMaskView()
    private var isFirstTimePlayMusic = true
    private var numberOfFinishedRay = 0
    private var audioPlayer: AVAudioPlayer?
    private var onboardingMaskView = OnboardingMaskView()
    
    @IBOutlet weak var musicReplayView: UIButton!
    @IBOutlet var switchView: UIView!
    private var gameSwitch: SwitchView?
    
    private var isVirgin: Bool?
    private var shouldShowNextLevel: Bool = false
    private var queue = dispatch_queue_create("CHECKING_SERIAL_QUEUE", DISPATCH_QUEUE_SERIAL)
    
    private var grid: GOGrid {
        get {
            return gameLevel.grid
        }
    }
    private var xNodes: [String: XNode] {
        get {
            return gameLevel.xNodes
        }
    }
    /// a boolean value indicate if the game play is in preview mode or not
    private var isPreview: Bool = false
    
    struct RayDefaults {
        static let initialStrokeEnd: CGFloat = 1.0
        static let strokeColor = UIColor(white: 1, alpha: 0.2).CGColor
        static let fillColor = UIColor.clearColor().CGColor
        static let lineWidth: CGFloat = 5.0
        static let shadowRadius: CGFloat = 2
        static let shadowColor = UIColor.whiteColor().CGColor
        static let shadowOpacity: Float = 0.9
        static let animationKeyPath = "strokeEnd"
        static let animationFromValue: CGFloat = 0.0
        static let animationToValue: CGFloat = 1.0
        static let delayCoefficient: CGFloat = 0.9
    }
    
    struct GameNodeDefaults {
        static let strokeEnd: CGFloat = 1.0
        static let lineWidth: CGFloat = 0
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: Float = 0.5
        static let shadowOffset = CGSizeZero
        static let movableObjectAlpha: CGFloat = 0.3
        static let animationKeyPath = "fillColor"
        static let animationDuration: NSTimeInterval = 0.4
        static let fadeInAnimationDuration: NSTimeInterval = 0.3
        static let fadeInAnimationUnitDelay: NSTimeInterval = 0.1
        
        static let emitterMarkViewFrame = CGRectMake(0, 0, Constant.rayWidth * 2,
            Constant.rayWidth * 2)
        static let emitterMarkViewBackgroundColor = UIColor.whiteColor()
        static let emitterMarkViewCornerRadius = Constant.rayWidth
    }
    
    struct Defaults {
        static let gameSwitchFrame = CGRectMake(0, 0, 1024, 90)
        static let oscillationDefaultDirection = CGVectorMake(1, 0)
        static let numberOfGameLevelPerSection = 6
        static let lastGameLevelIndexRemainder = 5
        static let defaultBackgroundImageName = "mainbackground"
        static let randomStringLength = 20
        static let successCheckDelayCoefficient: Float = 0.5
        static let gameCenterPercentageFull: Double = 100.0
    }
    
    class func getInstance(gameLevel: GameLevel, isPreview:Bool) -> GameViewController {
        let storyboard = UIStoryboard(name: StoryboardIdentifier.StoryBoardID, bundle: nil)
        let identifier = StoryboardIdentifier.Game
        let viewController = storyboard.instantiateViewControllerWithIdentifier(identifier)
            as! GameViewController
        viewController.gameLevel = gameLevel
        viewController.originalLevel = gameLevel.deepCopy()
        viewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        viewController.isPreview = isPreview
        
        // increase game stats
        if !isPreview {
            GameStats.increaseTotalGamePlay()
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpBackground()
        self.setUpSwitchView()
        self.pauseMask.delegate = self
        self.transitionMask.delegate = self
        self.musicMask.delegate = self
        self.showTargetMusicMask()
        
        if self.isPreview {
            self.transitionMask.shouldShowButtons = false
        }
    }
    
    private func reloadLevel(gameLevel: GameLevel) {
        self.isVirgin = nil
        self.isFirstTimePlayMusic = true
        self.clear()
        self.gameLevel = gameLevel
        self.originalLevel = gameLevel.deepCopy()
        self.visitedNoteList = [XNote]()
        self.visitedPlanckList = [XNode]()
        self.gameSwitch?.setOff()
        // increase game stats
        if !isPreview {
            GameStats.increaseTotalGamePlay()
        }
        self.showTargetMusicMask()
        self.setUpBackground()
    }
    
    private func clear() {
        self.clearRay()
        self.clearDevice()
    }
    
    private func clearDevice() {
        for (key, view) in self.deviceViews {
            view.removeFromSuperview()
        }
        self.deviceViews = [String: UIView]()
    }
    
    private func setUpSwitchView() {
        self.gameSwitch = SwitchView()
        self.gameSwitch!.frame = Defaults.gameSwitchFrame
        self.switchView.addSubview(self.gameSwitch!)
    }
    
    @IBAction func switchViewDidTapped(sender: UITapGestureRecognizer) {
        self.gameSwitch!.toggle()
        
        if self.gameSwitch!.isOn {
            if self.isVirgin == nil {
                self.isVirgin = true
            } else if self.isVirgin! {
                self.isVirgin = false
            }
            // increase game statistics
            if !self.isPreview {
                GameStats.increaseTotalLightFire()
            }
            
            self.onboardingMaskView.clear()
            
            self.shootRay()
        } else {
            self.clearRay()
        }
    }
    
    @IBAction func viewDidTapped(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(sender.view)
        if let node = self.grid.getInstrumentAtPoint(location) {
            OscillationManager.oscillateView(
                self.deviceViews[node.id]!,
                direction: Defaults.oscillationDefaultDirection)
            if let sound = self.xNodes[node.id]?.getSound() {
                audioPlayer = AVAudioPlayer(contentsOfURL: sound, error: nil)
                audioPlayer!.prepareToPlay()
                audioPlayer!.play()
            }
            
            if !self.isNodeFixed(node) {
                self.gameSwitch!.setOff()
                self.clearRay()
                updateDirection(node)
            }
        }
    }
    
    private var firstLocation: CGPoint?
    private var lastLocation: CGPoint?
    private var firstViewCenter: CGPoint?
    private var touchedNode: GOOpticRep?
    
    @IBAction func pauseButtonDidClicked(sender: UIButton) {
        self.view.addSubview(self.pauseMask)
        self.pauseMask.show()
    }
    
    @IBAction func viewDidPanned(sender: UIPanGestureRecognizer) {
        let location = sender.locationInView(self.view)
        if sender.state == UIGestureRecognizerState.Began || touchedNode == nil {
            firstLocation = location
            lastLocation = location
            touchedNode = self.grid.getInstrumentAtPoint(location)
            if let node = touchedNode {
                if !self.isNodeFixed(node) {
                    firstViewCenter = self.deviceViews[node.id]!.center
                    self.gameSwitch!.setOff()
                    self.clearRay()
                } else {
                    touchedNode = nil
                }
            }
        }
        
        if let node = touchedNode {
            let view = self.deviceViews[node.id]!
            view.center = CGPointMake(view.center.x + location.x - lastLocation!.x,
                view.center.y + location.y - lastLocation!.y)
            lastLocation = location
            if sender.state == UIGestureRecognizerState.Ended {
                
                let offset = CGPointMake(location.x - firstLocation!.x,
                    location.y - firstLocation!.y)
                
                self.moveNode(node, from: firstViewCenter!, offset: offset)
                
                lastLocation = nil
                firstLocation = nil
                firstViewCenter = nil
                touchedNode = nil
            }
        }
    }
    
    private func setUpBackground() {
        var patternImage = UIImage()
        if gameLevel.index < Defaults.numberOfGameLevelPerSection {
            patternImage = UIImage(named: Defaults.defaultBackgroundImageName)!
        } else {
            patternImage = UIImage(named: "background-\(gameLevel.index / 6)")!
        }
        
        self.view.backgroundColor = UIColor(patternImage: patternImage)
    }
    
    private func updateDirection(node: GOOpticRep) {
        let newDirectionIndex = Int(round(node.direction.angleFromXPlus /
            self.grid.unitDegree)) + 1
        let originalDirection = node.direction
        let effectDirection = CGVector.vectorFromXPlusRadius(CGFloat(newDirectionIndex) *
            self.grid.unitDegree)
        self.updateDirection(node, startVector: originalDirection,
            currentVector: effectDirection)
    }
    
    private func updateDirection(node: GOOpticRep, startVector: CGVector,
        currentVector: CGVector) {
        var angle = CGVector.angleFrom(startVector, to: currentVector)
        let nodeAngle = node.direction.angleFromXPlus
        let effectAngle = angle + nodeAngle
        let count = round(effectAngle / self.grid.unitDegree)
        let finalAngle = self.grid.unitDegree * count
        angle = finalAngle - nodeAngle
        node.setNodeDirection(CGVector.vectorFromXPlusRadius(finalAngle))
        if let view = self.deviceViews[node.id] {
            var layerTransform = CATransform3DRotate(view.layer.transform,
                angle, 0, 0, 1)
            view.layer.transform = layerTransform
        }
    }
    
    private func isNodeFixed(node: GOOpticRep) -> Bool {
        if let xNode = self.xNodes[node.id] {
            return xNode.isFixed
        } else {
            fatalError(ErrorMsg.nodeInconsistency)
        }
    }
    
    private var nodeCount = 0
    private func setUpGrid() {
        // in case user replay the music
        if !isFirstTimePlayMusic {
            return
        }
        
        for (key, node) in self.grid.instruments {
            self.addNode(node, strokeColor: self.xNodes[node.id]!.strokeColor)
            nodeCount++
        }
        
        nodeCount = 0
        self.grid.delegate = self
    }
    
    private func shootRay() {
        self.clearRay()
        for (name, item) in self.grid.instruments {
            if let item = item as? GOEmitterRep {
                self.addRay(item.getRay())
            }
        }
    }
    
    private func addRay(ray: GORay) {
        var newTag = String.generateRandomString(Defaults.randomStringLength)
        self.rays[newTag] = [(CGPoint, GOSegment?)]()
        self.rayLayers[newTag] = [CAShapeLayer]()
        self.grid.startCriticalPointsCalculationWithRay(ray, withTag: newTag)
    }
    
    private func clearRay() {
        self.grid.stopSubsequentCalculation()
        for (key, layers) in self.rayLayers {
            for layer in layers {
                layer.removeFromSuperlayer()
            }
        }
        
        for (key, layers) in self.emitterLayers {
            for layer in layers {
                layer.removeFromSuperlayer()
            }
        }
        
        self.audioPlayerList.removeAll(keepCapacity: false)
        self.rayLayers = [String: [CAShapeLayer]]()
        self.rays = [String: [(CGPoint, GOSegment?)]]()
        self.music.reset()
        self.pathDistances = [String: CGFloat]()
        self.visitedPlanckList = [XNode]()
        self.numberOfFinishedRay = 0
    }
    
    private func drawRay(tag: String, currentIndex: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.rays.count == 0 {
                // there is no rays to draw
                // this typically happens after user clear the scene
                // but the last round of calculation still does not stop
                return
            }
            
            if currentIndex < self.rays[tag]?.count {
                // the ray is drawn while the calculation is going on
                // if currently the drawing is not finished, we continue
                let rayLayer = CAShapeLayer()
                rayLayer.strokeEnd = RayDefaults.initialStrokeEnd
                rayLayer.strokeColor = RayDefaults.strokeColor
                rayLayer.fillColor = RayDefaults.fillColor
                rayLayer.lineWidth = RayDefaults.lineWidth
                
                // rayLayers stores all the layers of ray
                // each segment of the ray is represent as a shapelayer,
                // hence we append the layer to the corresponding slot.
                self.rayLayers[tag]?.append(rayLayer)
                
                var path = UIBezierPath()
                // rayPath is the collection of each turning (critical) point
                let rayPath = self.rays[tag]!
                
                // getting the two end of the path that is currently drawing
                let prevPoint = rayPath[currentIndex - 1]
                let currentPoint = rayPath[currentIndex]
                path.lineJoinStyle = kCGLineJoinBevel
                path.lineCapStyle = kCGLineCapRound
                path.moveToPoint(prevPoint.0)
                path.addLineToPoint(currentPoint.0)

                // distance is used to calculate the delay between the two notes
                let distance = prevPoint.0.getDistanceToPoint(currentPoint.0)
                rayLayer.path = path.CGPath
                rayLayer.shadowOffset = CGSizeZero
                rayLayer.shadowRadius = RayDefaults.shadowRadius
                rayLayer.shadowColor = RayDefaults.shadowColor
                rayLayer.shadowOpacity = RayDefaults.shadowOpacity
                
                self.view.layer.addSublayer(rayLayer)
                
                // the duration of the drawing animation
                let delay = distance / Constant.lightSpeedBase
                
                let pathAnimation = CABasicAnimation(keyPath: RayDefaults.animationKeyPath)
                pathAnimation.fromValue = RayDefaults.animationFromValue
                pathAnimation.toValue = RayDefaults.animationToValue
                pathAnimation.duration = CFTimeInterval(delay)
                pathAnimation.fillMode = kCAFillModeForwards
                pathAnimation.timingFunction = CAMediaTimingFunction(name:
                    kCAMediaTimingFunctionLinear)
                
                rayLayer.addAnimation(pathAnimation, forKey: pathAnimation.keyPath)
                if currentIndex > 1 {
                    // this happen after the last delay, we can play the previous
                    // note already
                    self.playNote(prevPoint.1, tag: tag)
                    
                    // handle the oscillation of the instrument
                    OscillationManager.oscillateView(
                        self.deviceViews[prevPoint.1!.parent]!,
                        direction: CGVectorMake(
                            currentPoint.0.x - prevPoint.0.x,
                            currentPoint.0.y - prevPoint.0.y))
                }
                
                // keep track of the length of the current path
                if self.pathDistances[tag] == nil {
                    self.pathDistances[tag] = CGFloat(0)
                }
                
                // add the newly drawn path distance to the total distance
                self.pathDistances[tag]! += distance
                let delayInNanoSeconds = RayDefaults.delayCoefficient *
                    delay * CGFloat(NSEC_PER_SEC)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    Int64(delayInNanoSeconds)), dispatch_get_main_queue()) {
                        // wait for the animation to complete, then start 
                        // the next drawing and playing
                        self.drawRay(tag, currentIndex: currentIndex + 1)
                }
            } else {
                // we have already finished one ray
                self.numberOfFinishedRay++
                
                // remember to play the last note
                if let rayPath = self.rays[tag] {
                    let prevPoint = rayPath[currentIndex - 1]
                    self.playNote(prevPoint.1, tag: tag)
                }
                
                // if every rays are finished, we can start checking whether
                // the player fulfil the winning condition for this level
                if self.numberOfFinishedRay == self.rays.count {
                    dispatch_async(self.queue, {
                        // if the music is similar in terms of rhythm and melody
                        if self.music.isSimilarTo(self.originalLevel.targetMusic) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                Int64(Float(NSEC_PER_SEC) * Defaults.successCheckDelayCoefficient)),
                                dispatch_get_main_queue()) {
                                if self.isVirgin! {
                                    // in this case, the user achieve the target
                                    // at the first time of trial, 3 stars
                                    self.showBadgeMask(3)
                                    if self.originalLevel.bestScore < 3 {
                                        self.originalLevel.bestScore = 3
                                    }
                                } else {
                                    // the player might have tried many times
                                    // 2 stars
                                    self.showBadgeMask(2)
                                    if self.originalLevel.bestScore < 2 {
                                        self.originalLevel.bestScore = 2
                                    }
                                }
                            }
                            
                            // navigating the user to the level trasition mask
                            self.shouldShowNextLevel = true
                        } else if (self.originalLevel.bestScore < 1)
                            && (self.visitedNoteList.count == self.gameLevel.targetMusic.music.count) {
                            // we only show the 1 star result if the user haven't 
                            // achieved it. If the user already finished 1 star
                            // we won't disturbing him by show the mask again 
                            // and again
                                
                            // one star is achieved if the user hit every notes
                            // in the target music (not necessary the same number)
                            // or rhythm
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                Int64(Float(NSEC_PER_SEC) * 1.5)), dispatch_get_main_queue()) {
                                //1 means one star
                                self.showBadgeMask(1)
                                if self.originalLevel.bestScore < 1 {
                                    self.originalLevel.bestScore = 1
                                }
                            }
                            self.shouldShowNextLevel = true
                        } else {
                            self.shouldShowNextLevel = false
                        }
                    })
                }
            }
        }
    }
    
    private func playNote(segment: GOSegment?, tag: String) {
        if let edge = segment {
            if let device = xNodes[edge.parent] {
                if !contains(self.visitedPlanckList, device) {
                    self.visitedPlanckList.append(device)
                    if let note = device.getNote() {
                        if (note.isIn(self.gameLevel.targetNotes)) &&
                            (!note.isIn(self.visitedNoteList)) {
                                self.visitedNoteList.append(note)
                        }
                    }
                }
                
                if let sound = device.getSound() {
                    let audioPlayer = AVAudioPlayer(contentsOfURL: sound, error: nil)
                    self.audioPlayerList.append(audioPlayer)
                    audioPlayer.prepareToPlay()
                    audioPlayer.play()
                    
                    let note = device.getNote()!
                    self.music.appendDistance(self.pathDistances[tag]!, forNote: note)
                }
            } else {
                fatalError(ErrorMsg.nodeNotExist)
            }
        }
    }
    
    private func showBadgeMask(numberOfBadge: Int) {
        self.view.addSubview(self.transitionMask)
        self.transitionMask.show(numberOfBadge, isSectionFinished: self.originalLevel.index %
            Defaults.numberOfGameLevelPerSection == Defaults.lastGameLevelIndexRemainder)
    }
    
    private func showTargetMusicMask() {
        self.view.addSubview(self.musicMask)
        self.musicMask.show(self.gameLevel.targetMusic)
        self.view.userInteractionEnabled = false
    }
    
    @IBAction func playMusic(sender: UIButton) {
        showTargetMusicMask()
    }
    
    private func addNode(node: GOOpticRep, strokeColor: UIColor) -> Bool{
        var coordinateBackup = node.center
        node.setNodeCenter(GOCoordinate(x: self.grid.width/2, y: self.grid.height/2))
        self.grid.addInstrument(node)
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = UIColor.clearColor()

        let layer = CAShapeLayer()
        layer.fillColor = strokeColor.CGColor
        layer.shadowColor = strokeColor.CGColor
        layer.strokeEnd = GameNodeDefaults.strokeEnd
        layer.lineWidth = GameNodeDefaults.lineWidth
        layer.shadowRadius = GameNodeDefaults.shadowRadius
        layer.shadowOpacity = GameNodeDefaults.shadowOpacity
        layer.shadowOffset = GameNodeDefaults.shadowOffset
        layer.path = self.grid.getInstrumentDisplayPathForID(node.id)?.CGPath
        
        if !isNodeFixed(node) {
            var fillColorAnimation = CABasicAnimation(keyPath: GameNodeDefaults.animationKeyPath)
            fillColorAnimation.duration = GameNodeDefaults.animationDuration
            fillColorAnimation.fromValue = strokeColor.CGColor
            fillColorAnimation.toValue = strokeColor.colorWithAlphaComponent(
                GameNodeDefaults.movableObjectAlpha).CGColor
            fillColorAnimation.repeatCount = HUGE
            fillColorAnimation.autoreverses = true
            layer.addAnimation(fillColorAnimation, forKey: fillColorAnimation.keyPath)
        }
        
        if let emitter = node as? GOEmitterRep {
            let markView  = UIView(frame: GameNodeDefaults.emitterMarkViewFrame)
            markView.backgroundColor = GameNodeDefaults.emitterMarkViewBackgroundColor
            markView.layer.cornerRadius = GameNodeDefaults.emitterMarkViewCornerRadius
            markView.center = view.center
            let degree = node.direction.angleFromXPlus
            markView.transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(degree),
                emitter.length * self.grid.unitLength / 2, 0)
            
            view.addSubview(markView)
        }
        
        view.layer.addSublayer(layer)
        
        self.deviceViews[node.id] = view
        var offsetX = CGFloat(coordinateBackup.x - node.center.x) * self.grid.unitLength
        var offsetY = CGFloat(coordinateBackup.y - node.center.y) * self.grid.unitLength
        var offset = CGPointMake(offsetX, offsetY)
        
        if !self.moveNode(node, from: self.view.center, offset: offset) {
            view.removeFromSuperview()
            self.grid.removeInstrumentForID(node.id)
            return false
        }
        
        view.alpha = 0
        self.view.insertSubview(view, atIndex: 0)
        UIView.animateWithDuration(
            GameNodeDefaults.fadeInAnimationDuration,
            delay: GameNodeDefaults.fadeInAnimationUnitDelay * Double(nodeCount),
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                view.alpha = 1
            }, completion: {
                finished in
                
            }
        )
        
        return true
    }

    private func moveNode(node: GOOpticRep, from: CGPoint,offset: CGPoint) -> Bool{
        let offsetX = offset.x
        let offsetY = offset.y
        
        let originalDisplayPoint = self.grid.getCenterForGridCell(node.center)
        let effectDisplayPoint = CGPointMake(originalDisplayPoint.x + offsetX,
            originalDisplayPoint.y + offsetY)
        
        let centerBackup = node.center
        
        //check whether the node will overlap with other nodes with the new center
        node.setNodeCenter(self.grid.getGridCoordinateForPoint(effectDisplayPoint))
        if self.grid.isInstrumentOverlappedWidthOthers(node) {
            //overlapped recover the center and view
            node.setNodeCenter(centerBackup)
            //recover the view
            let view = self.deviceViews[node.id]!
            view.center = originalDisplayPoint
            return false
        } else{
            //not overlap, move the view to the new position
            let view = self.deviceViews[node.id]!
            let finalDisplayPoint = self.grid.getCenterForGridCell(node.center)
            let finalX = finalDisplayPoint.x - originalDisplayPoint.x + from.x
            let finalY = finalDisplayPoint.y - originalDisplayPoint.y + from.y
            
            view.center = CGPointMake(finalX, finalY)
            return true
        }
    }
    

    private func moveNode(node: GOOpticRep, to: GOCoordinate) -> Bool{
        let originalCenter = self.grid.getCenterForGridCell(node.center)
        let finalCenter = self.grid.getCenterForGridCell(to)
        let offsetX = finalCenter.x - originalCenter.x
        let offsetY = finalCenter.y - originalCenter.y
        let offset = CGPointMake(offsetX, offsetY)
        return self.moveNode(node, from: originalCenter, offset: offset)
    }
    
    private func reportAchievements(levelIndex: Int) {
        let achievements = [XGameCenter.achi_firstblood,
            XGameCenter.achi_finish1, XGameCenter.achi_finish2,
            XGameCenter.achi_finish3, XGameCenter.achi_finish4,
            XGameCenter.achi_finish5]
        
        if levelIndex == 0 {
            GamiCent.reportAchievements(
                percent: Defaults.gameCenterPercentageFull,
                achievementID: XGameCenter.achi_firstblood,
                isShowBanner: true,
                completion: nil
            )
        } else if (levelIndex + 1) % Constant.levelInSection == 0  {
            // since there are 6 levels in a section, then the last (level + 1) 
            // divide by 6 will be the section number
            let section = (levelIndex + 1) / Constant.levelInSection
            
            // finished the last level in a section
            GamiCent.reportAchievements(percent: Defaults.gameCenterPercentageFull,
                achievementID: achievements[section], isShowBanner: true, completion: nil)
        }
    }

}

extension GameViewController: GOGridDelegate {
    func grid(grid: GOGrid, didProduceNewCriticalPoint point: CGPoint,
        onEdge edge: GOSegment?, forRayWithTag tag: String) {
        if self.rays.count == 0 {
            // waiting for thread to complete
            return
        }
        
        self.rays[tag]?.append((point, edge))
        if self.rays[tag]?.count == 2 {
            // when there are 2 points, start drawing
            drawRay(tag, currentIndex: 1)
        }
    }
    
    func gridDidFinishCalculation(grid: GOGrid, forRayWithTag tag: String) {
        return
    }
}

extension GameViewController: PauseMaskViewDelegate {
    func buttonDidClickedAtIndex(index: Int) {
        switch index {
        case 0:
            self.dismissViewController()
            
            if !self.isPreview {
                // play background music
                NSNotificationCenter.defaultCenter().postNotificationName(
                    HomeViewDefaults.startPlayingKey, object: nil)
            }
            
        case 2:
            self.pauseMask.hide()
            
        default:
            self.reloadLevel(self.originalLevel)
            self.pauseMask.hide()
        }
    }
}

extension GameViewController: LevelTransitionMaskViewDelegate {
    func viewDidDismiss(view: LevelTransitionMaskView, withButtonClickedAtIndex
        index: Int) {
        self.onboardingMaskView.clear()
        self.onboardingMaskView.removeFromSuperview()
        // save current game if it is not preview mode
        if !isPreview {
            
            reportAchievements(self.gameLevel.index)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                StorageManager.defaultManager.saveCurrentLevel(self.originalLevel)
            })
            
            if let nextLevel = GameLevel.loadGameWithIndex(self.gameLevel.indexForNextLevel) {
                // unlock next level and save it
                nextLevel.isUnlock = true
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    StorageManager.defaultManager.saveCurrentLevel(nextLevel)
                })
            }
        }
        
        if index == 2 {
            if self.shouldShowNextLevel {
                if let nextLevel = GameLevel.loadGameWithIndex(self.gameLevel.indexForNextLevel) {
                    self.reloadLevel(nextLevel)
                } else {
                    // have finished all current game
                    self.dismissViewController()
                    
                    // play background music
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        HomeViewDefaults.startPlayingKey, object: nil)
                }
            }
        } else {
            self.buttonDidClickedAtIndex(index)
        }
        
    }
}

extension GameViewController: TargetMusicMaskViewDelegate {
    func didFinishPlaying() {
        if !self.isPreview {
            GameStats.increaseTotalMusicPlayed()
        }
        self.musicMask.hide()
        self.view.userInteractionEnabled = true
    }
    
    func musicMaskViewDidDismiss(view: TargetMusicMaskView) {
        self.setUpGrid()
        self.checkOnboarding()
        isFirstTimePlayMusic = false
    }
}

//onboarding

extension GameViewController {
    private struct OnboardingSpecifics {
        static let levelZeroIndex = 0
        static let levelZeroText = "tap the switch to shoot the light"
        static let levelZeroMaskPathPoints = [CGPointMake(0, 768), CGPointMake(0, 668), CGPointMake(100, 668), CGPointMake(150, 718), CGPointMake(150, 768)]
        static let levelZeroTapPosition = CGPoint(x: 80, y: 708)
        
        static let levelOneIndex = 1
        static let levelOneMaskPathRadius: CGFloat = 100
        static let levelOneTapPosition = CGPointMake(500, 125)
        static let levelOneLabelSpecifics = [
            ("tap a node to play its sound", CGPointMake(500, 185)),
            ("shining node is moveable, tap a shining node to change its direction", CGPointMake(600, 530)),
            ("rotate the node to the dashed frame, and shoot the light", CGPointMake(512, 670))
        ]
        
        static let levelTwoIndex = 2
        static let levelTwoMaskPathRadius: CGFloat = 200
        static let levelTwoStartPointYOffset: CGFloat = 20
        static let levelTwoEndPointYOffset: CGFloat = -20
        static let levelTwoLabelSpecifics = [
            ("drag a moveable node to move it around", CGPointMake(635, 230)),
            ("move and rotate the node to fit the dashed frame, then shoot the light", CGPointMake(635, 700))
        ]
        
        static let levelThreeIndex = 3
        static let levelThreeLabelSpecifics = [
            ("get familiar with devices in Planck", CGPointMake(512, 30)),
            ("concave lens - diverge light", CGPointMake(208, 490)),
            ("flat mirror - reflect light", CGPointMake(528, 420)),
            ("flat lens - light penetrate it", CGPointMake(704, 230)),
            ("convex lens - converge light", CGPointMake(750, 610)),
            ("wall - stop light", CGPointMake(944, 420))
        ]
        
        static let levelFourIndex = 4
        static let levelFourLabelSpecifics = [
            ("target music can be hard", CGPointMake(650, 39.5)),
            ("but you can always tap music button to replay it", CGPointMake(680, 89.5)),
        ]
        static let levelFourTapPosition = CGPointMake(913.5, 49.5)
        
        static let levelFiveIndex = 5
        static let levelFiveLabelText = "it's your turn, try to solve this simple level"
        static let levelFiveLabelPosition = CGPointMake(512, 60)
    }
    
    func checkOnboarding() {
        if self.gameLevel.index == OnboardingSpecifics.levelZeroIndex {
            let welcomeLabel = self.onboardingMaskView.addLabelWithText(OnboardingSpecifics.levelZeroText, position: self.view.center)
            var maskPath = UIBezierPath()
            maskPath.moveToPoint(OnboardingSpecifics.levelZeroMaskPathPoints[0])
            for var i = 1; i < OnboardingSpecifics.levelZeroMaskPathPoints.count; i++ {
                maskPath.addLineToPoint(OnboardingSpecifics.levelZeroMaskPathPoints[i])
            }
            maskPath.closePath()
            self.onboardingMaskView.drawMask(maskPath, animated: true)
            self.onboardingMaskView.showTapGuidianceAtPoint(OnboardingSpecifics.levelZeroTapPosition, repeat: true)
            self.view.addSubview(self.onboardingMaskView)
        } else if self.gameLevel.index == OnboardingSpecifics.levelOneIndex {
            var movableObject = self.gameLevel.getOriginalMovableNodes()[0]
            var movableObjectPath = self.gameLevel.originalGrid.getInstrumentDisplayPathForID(movableObject.id)
            var maskPath = UIBezierPath()
            maskPath.addArcWithCenter(
                self.grid.getCenterForGridCell(movableObject.center),
                radius: OnboardingSpecifics.levelOneMaskPathRadius,
                startAngle: 0,
                endAngle: CGFloat(2 * M_PI),
                clockwise: true)
            self.onboardingMaskView.drawMask(maskPath, animated: false)
            self.onboardingMaskView.showMask(true)
            self.onboardingMaskView.drawDashedTarget(movableObjectPath!)
            self.onboardingMaskView.showTapGuidianceAtPoint(self.gameLevel.originalGrid.getCenterForGridCell(movableObject.center), repeat: true)
            self.onboardingMaskView.showTapGuidianceAtPoint(OnboardingSpecifics.levelOneTapPosition, repeat: true)
            
            for (text, position) in OnboardingSpecifics.levelOneLabelSpecifics {
                self.onboardingMaskView.addLabelWithText(text, position: position)
            }
            self.view.addSubview(self.onboardingMaskView)
        } else if self.gameLevel.index == OnboardingSpecifics.levelTwoIndex {
            var movableObject = self.gameLevel.getOriginalMovableNodes()[0]
            var currentMovObject = self.gameLevel.getCurrentMovableNodes()[0]
            
            var movableObjectPath = self.gameLevel.originalGrid.getInstrumentDisplayPathForID(movableObject.id)
            var maskPath = UIBezierPath()
            maskPath.addArcWithCenter(
                self.grid.getCenterForGridCell(movableObject.center),
                radius: OnboardingSpecifics.levelTwoMaskPathRadius,
                startAngle: 0,
                endAngle: CGFloat(2 * M_PI),
                clockwise: true)
            self.onboardingMaskView.drawMask(maskPath, animated: false)
            self.onboardingMaskView.showMask(true)
            self.onboardingMaskView.drawDashedTarget(movableObjectPath!)
            
            
            let fromCenterPoint = gameLevel.grid.getCenterForGridCell(currentMovObject.center)
            let toCenterPoint = gameLevel.grid.getCenterForGridCell(movableObject.center)
            
            let startPoint = CGPoint(x: fromCenterPoint.x, y: fromCenterPoint.y + OnboardingSpecifics.levelTwoStartPointYOffset)
            let endPoint = CGPoint(x: toCenterPoint.x, y: toCenterPoint.y + OnboardingSpecifics.levelTwoEndPointYOffset)
            
            self.onboardingMaskView.showDragGuidianceFromPoint(startPoint, to: endPoint, repeat: true)
            
            for (text, position) in OnboardingSpecifics.levelTwoLabelSpecifics {
                self.onboardingMaskView.addLabelWithText(text, position: position)
            }
            
            self.view.addSubview(self.onboardingMaskView)
        } else if self.gameLevel.index == OnboardingSpecifics.levelThreeIndex{
            var movableObject = self.gameLevel.getOriginalMovableNodes()[0]
            
            var movableObjectPath = self.gameLevel.originalGrid.getInstrumentDisplayPathForID(movableObject.id)
            self.onboardingMaskView.drawDashedTarget(movableObjectPath!)
            for (text, position) in OnboardingSpecifics.levelThreeLabelSpecifics {
                self.onboardingMaskView.addLabelWithText(text, position: position)
            }
            self.view.addSubview(self.onboardingMaskView)
        } else if self.gameLevel.index == OnboardingSpecifics.levelFourIndex{
            var movableObject = self.gameLevel.getOriginalMovableNodes()[0]
            var movableObjectPath = self.gameLevel.originalGrid.getInstrumentDisplayPathForID(movableObject.id)
            self.onboardingMaskView.drawDashedTarget(movableObjectPath!)
            self.onboardingMaskView.showTapGuidianceAtPoint(OnboardingSpecifics.levelFourTapPosition, repeat: true)
            
            for (text, position) in OnboardingSpecifics.levelFourLabelSpecifics {
                self.onboardingMaskView.addLabelWithText(text, position: position)
            }
            
            self.view.addSubview(self.onboardingMaskView)
        } else if self.gameLevel.index == OnboardingSpecifics.levelFiveIndex {
            self.onboardingMaskView.addLabelWithText(OnboardingSpecifics.levelFiveLabelText, position: OnboardingSpecifics.levelFiveLabelPosition)
            self.view.addSubview(self.onboardingMaskView)
        }
    }
}

