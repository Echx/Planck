//
//  GameLevel.swift
//  Planck
//
//  Created by Jiang Sheng on 5/4/15.
//  Copyright (c) 2015 Echx. All rights reserved.

// This class defines the data structure which stores each of the game levels
class GameLevel: NSObject, NSCoding, Comparable, Equatable {
    private let defaultName = "Deadline"
    
    /// The puzzle grid contained in this level
    var grid: GOGrid
    
    /// the solution grid copy (designerview)
    var originalGrid: GOGrid
    
    /// The XNodes contained in this level
    var xNodes: [String: XNode]
    
    /// The name of this level
    var name: String
    
    /// The index of this level
    var index: Int
    
    /// The desire music for this level
    var targetMusic: XMusic = XMusic()
    
    /// The score user achieve on this level
    var bestScore:Int = 0
    
    /// Whether this level is unlocked, default false
    var isUnlock:Bool = false
    
    var targetNotes: [XNote] {
        get {
            return self.targetMusic.music.keys.array
        }
    }
    
    /// The index for next level
    var indexForNextLevel: Int {
        get {
            return index + 1
        }
    }
    
    init(levelName: String, levelIndex: Int, grid: GOGrid, solvedGrid: GOGrid,
        nodes: [String: XNode], targetMusic: XMusic) {
        self.name           = levelName
        self.index          = levelIndex
        self.grid           = grid
        self.originalGrid   = solvedGrid
        self.xNodes         = nodes
        self.targetMusic    = targetMusic
    }
    
    override init() {
        self.name = ""
        self.index = 0
        self.grid = GOGrid(width: 0, height: 0, andUnitLength: 0)
        self.originalGrid = GOGrid(width: 0, height: 0, andUnitLength: 0)
        self.xNodes = [String: XNode]()
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        var levelName       = aDecoder.decodeObjectForKey(NSCodingKey.GameName) as! String
        var index           = aDecoder.decodeObjectForKey(NSCodingKey.GameIndex) as! Int
        var grid            = aDecoder.decodeObjectForKey(NSCodingKey.GameGrid) as! GOGrid
        var originalGrid    = aDecoder.decodeObjectForKey(NSCodingKey.GameGridCopy) as! GOGrid
        var xNodes          = aDecoder.decodeObjectForKey(NSCodingKey.GameNodes) as! [String: XNode]
        var music           = aDecoder.decodeObjectForKey(NSCodingKey.GameTargetMusic) as! XMusic
        var bestScore       = aDecoder.decodeObjectForKey(NSCodingKey.GameBestScore) as! Int
        var isUnlock        = aDecoder.decodeBoolForKey(NSCodingKey.GameUnlock)
        
        self.init(levelName:levelName, levelIndex: index,
                    grid:grid, solvedGrid: originalGrid,
                    nodes:xNodes, targetMusic:music)
        
        self.bestScore = bestScore
        self.isUnlock = isUnlock
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name,          forKey: NSCodingKey.GameName)
        aCoder.encodeObject(self.index,         forKey: NSCodingKey.GameIndex)
        aCoder.encodeObject(self.grid,          forKey: NSCodingKey.GameGrid)
        aCoder.encodeObject(self.originalGrid,  forKey: NSCodingKey.GameGridCopy)
        aCoder.encodeObject(self.xNodes,        forKey: NSCodingKey.GameNodes)
        aCoder.encodeObject(self.targetMusic,   forKey: NSCodingKey.GameTargetMusic)
        aCoder.encodeObject(self.bestScore,     forKey: NSCodingKey.GameBestScore)
        aCoder.encodeBool(self.isUnlock,        forKey: NSCodingKey.GameUnlock)
    }
    
    // Get a game level from the given index
    // :param: the index of the game level needed to be retrieved
    // returns: the GameLevel objects for that particular level
    class func loadGameWithIndex(index:Int) -> GameLevel? {
        let totalGame = StorageManager.defaultManager.numOfLevel()
        if index < 0 || index >= totalGame {
            return nil
        }
        return StorageManager.defaultManager.loadAllLevel()[index]
    }
    
    // Count the total scores (tokens) user has achieved
    // returns: the total score
    class func countTotalScore() -> Int {
        let allLevels = StorageManager.defaultManager.loadAllLevel()
        var total:Int = 0
        for level in allLevels {
            total += level.bestScore
        }
        return total
    }
    
    //make a deep copy of the current gamelevel
    func deepCopy() -> GameLevel {
        return NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(self)) as! GameLevel
    }
    
    //get the movable nodes in original grid
    func getOriginalMovableNodes() -> [GOOpticRep]{
        var nodes = [GOOpticRep]()
        for (key, xNodes) in self.xNodes {
            if !xNodes.isFixed {
                nodes.append(self.originalGrid.instruments[key]!)
            }
        }
        return nodes
    }
    
    //get the movable nodes in grid
    func getCurrentMovableNodes() -> [GOOpticRep]{
        var nodes = [GOOpticRep]()
        for (key, xNodes) in self.xNodes {
            if !xNodes.isFixed {
                nodes.append(self.grid.instruments[key]!)
            }
        }
        return nodes
    }
}

func ==(lhs: GameLevel, rhs: GameLevel) -> Bool {
    return lhs.name == rhs.name && lhs.index == rhs.index
}

func <(lhs: GameLevel, rhs: GameLevel) -> Bool {
    return lhs.index < rhs.index
}

