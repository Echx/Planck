//
//  CGVector+XUtility.swift
//  Planck
//
//  Created by Wang Jinghan on 12/03/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import CoreGraphics

extension CGVector {
//    var length: CGFloat {
//        get {
//            return sqrt(self.dx * self.dx + self.dy * self.dy)
//        }
//    }
    
    //give result in [-PI, PI)
    var angleFromYPlus: CGFloat {
        get {
            var rawAngle = CGFloat(atan(self.dx / self.dy))
            
            if self.dx > 0 && self.dy > 0 {
                return rawAngle
            } else if self.dx < 0 && self.dy > 0 {
                return rawAngle
            } else if self.dx < 0 && self.dy < 0 {
                return CGFloat(-M_PI/2) - rawAngle
            } else if self.dx > 0 && self.dy < 0 {
                return CGFloat(M_PI/2) - rawAngle
            } else if self.dx == 0 && self.dy < 0 {
                return CGFloat(-M_PI)
            } else if self.dx == 0 && self.dy > 0 {
                return CGFloat(0)
            } else if self.dy == 0 && self.dx < 0 {
                return CGFloat(-M_PI/2)
            } else if self.dy == 0 && self.dx > 0 {
                return CGFloat(M_PI/2)
            } else {
                fatalError("undefined angle")
            }
        }
    }
    
    
    //give result in [-PI, PI)
//    var angleFromXPlus: CGFloat {
//        get {
//            var rawAngle = CGFloat(atan(self.dy / self.dx))
//            
//            if self.dx > 0 && self.dy > 0 {
//                return rawAngle
//            } else if self.dx < 0 && self.dy > 0 {
//                return CGFloat(M_PI) + rawAngle
//            } else if self.dx < 0 && self.dy < 0 {
//                return CGFloat(-M_PI) + rawAngle
//            } else if self.dx > 0 && self.dy < 0 {
//                return rawAngle
//            } else if self.dx == 0 && self.dy < 0 {
//                return CGFloat(-M_PI/2)
//            } else if self.dx == 0 && self.dy > 0 {
//                return CGFloat(M_PI/2)
//            } else if self.dy == 0 && self.dx < 0 {
//                return CGFloat(-M_PI)
//            } else if self.dy == 0 && self.dx > 0 {
//                return CGFloat(0)
//            } else {
//                fatalError("undefined angle")
//            }
//        }
//    }
    
    //give result in [0, PI)
    var angleFromXPlusScalar: CGFloat {
        get {
            var angleFromXPlus = self.angleFromXPlus
            if angleFromXPlus < 0 {
                angleFromXPlus += CGFloat(M_PI)
            }
            return angleFromXPlus
        }
    }
    
    //start from x plus
    static func vectorFromRadius(radius: CGFloat) -> CGVector{
        return CGVectorMake(cos(radius), sin(radius))
    }
    
    static func vectorFromYPlusRadius(radius: CGFloat) -> CGVector {
        return CGVectorMake(sin(radius), cos(radius))
    }
    
//    static func dot(v1: CGVector, v2: CGVector) -> CGFloat {
//        return v1.dx * v2.dx + v1.dy * v2.dy
//    }
    
    static func angleBetween(v1: CGVector, v2: CGVector) -> CGFloat {
        let dotProduct = dot(v1, v2: v2)
        let magnitude = v1.length * v2.length
        
        if (magnitude == 0) {
            return 0
        }
        
        var temp = dotProduct / magnitude
        if (temp > 1.0) {
            temp = 1.0
        } else if (temp < -1.0) {
            temp = -1.0
        }
        return acos(temp)
    }
    
    // the angle from v1 to v2 in anti-clockwise
    static func angleFrom(v1: CGVector, to v2: CGVector) -> CGFloat {
        var angle = v2.angleFromXPlus - v1.angleFromXPlus
        return angle >= 0 ? angle : angle + CGFloat(M_PI * 2)
    }
    
    func makePerpendicularVector() -> CGVector {
        return CGVectorMake(-self.dy, self.dx)
    }
    
    func normalize() -> CGVector {
        let dx = Constant.vectorUnitLength / self.length * self.dx
        let dy = Constant.vectorUnitLength / self.length * self.dy
        return CGVector(dx: dx, dy: dy)
    }
}