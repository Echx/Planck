//
//  XFlatMirror.swift
//  Planck
//
//  Created by Lei Mingyu on 10/03/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit
import SpriteKit

class XFlatMirror: XMirror {
    init(direction: CGVector) {
        super.init(
            texture: nil,
            color: MirrorDefaults.textureColor,
            size: MirrorDefaults.flatMirrorSize
        );
        self.direction = CGVector.vectorFromRadius(direction.angleFromXPlusScalar)
        self.setUp()
    }
    
    override func getNewDirectionAfterReflect(directionIn: CGVector) -> CGVector {
        if round(directionIn.angleFromXPlusScalar * Constant.angleCalculationPrecision) / Constant.angleCalculationPrecision
            == round(self.direction.angleFromXPlusScalar * Constant.angleCalculationPrecision) / Constant.angleCalculationPrecision {
            return CGVectorMake(-directionIn.dx, -directionIn.dy)
        }
        
        var mirrorAngle = self.direction.angleFromXPlusScalar
        var inAngle = directionIn.angleFromXPlus
        var outAngle = 2 * self.direction.angleFromXPlus - directionIn.angleFromXPlus
        return CGVector.vectorFromRadius(outAngle)
    }
    
    private func setUp() {
        self.runAction(SKAction.rotateToAngle(-direction.angleFromYPlus, duration: 0.0));
        self.setUpPhysicsProperties()
    }
    
    private func setUpPhysicsProperties() {
        self.physicsBody = SKPhysicsBody(rectangleOfSize: MirrorDefaults.flatMirrorSize)
        self.physicsBody!.dynamic = true
        self.physicsBody!.categoryBitMask = PhysicsCategory.flatMirror
        self.physicsBody!.contactTestBitMask = PhysicsCategory.photon
        self.physicsBody!.collisionBitMask = PhysicsCategory.none
        self.physicsBody!.usesPreciseCollisionDetection = true
    }
}

extension XFlatMirror: XContactable {
    func contactWithPhoton(photon: XPhoton) {
        photon.removeActionForKey(ActionKey.photonActionLinear)
        let direction = self.getNewDirectionAfterReflect(photon.direction)
        photon.setDirection(direction)
        photon.runAction(SKAction.repeatActionForever(photon.getAction()), withKey: ActionKey.photonActionLinear)
    }
}