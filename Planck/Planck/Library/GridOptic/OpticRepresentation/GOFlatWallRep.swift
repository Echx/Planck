//
//  GOFlatWallRep.swift
//  GridOptic
//
//  Created by Wang Jinghan on 01/04/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit

// Wall will stop the light once hit. A flat wall is a subclass of falt optic, 
// and it basically supports and only supports the method provided by its 
// parent class
class GOFlatWallRep: GOFlatOpticRep {
    override init(center: GOCoordinate, thickness: CGFloat, length: CGFloat, direction: CGVector, id: String) {
        super.init(center: center, thickness: thickness, length: length, direction: direction, id: id)
        self.setDeviceType(DeviceType.Wall)
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObjectForKey(GOCodingKey.optic_id) as! String
        let edges = aDecoder.decodeObjectForKey(GOCodingKey.optic_edges) as! [GOSegment]
        let typeRaw = aDecoder.decodeObjectForKey(GOCodingKey.optic_type) as! Int
        let type = DeviceType(rawValue: typeRaw)
        let thick = aDecoder.decodeObjectForKey(GOCodingKey.optic_thickness) as! CGFloat
        let length = aDecoder.decodeObjectForKey(GOCodingKey.optic_length) as! CGFloat
        let center = aDecoder.decodeObjectForKey(GOCodingKey.optic_center) as! GOCoordinate
        let direction = aDecoder.decodeCGVectorForKey(GOCodingKey.optic_direction)
        let refIndex = aDecoder.decodeObjectForKey(GOCodingKey.optic_refractionIndex) as! CGFloat
        
        self.init(center: center, thickness: thick, length: length, direction: direction, id: id)
        self.type = type!
        self.edges = edges
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: GOCodingKey.optic_id)
        aCoder.encodeObject(edges, forKey: GOCodingKey.optic_edges)
        aCoder.encodeObject(type.rawValue, forKey: GOCodingKey.optic_type)
        aCoder.encodeObject(thickness, forKey: GOCodingKey.optic_thickness)
        aCoder.encodeObject(length, forKey: GOCodingKey.optic_length)
        aCoder.encodeObject(center, forKey: GOCodingKey.optic_center)
        aCoder.encodeCGVector(direction, forKey: GOCodingKey.optic_direction)
        aCoder.encodeObject(refractionIndex, forKey: GOCodingKey.optic_refractionIndex)
    }
}
