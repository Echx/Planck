//
//  GameStasticViewController.swift
//  Planck
//
//  Created by Jiang Sheng on 17/4/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit

/// This view controller presents a game stastic table to the user
class GameStasticViewController: XViewController {
    class func getInstance() -> GameStasticViewController {
        let storyboard = UIStoryboard(
            name: StoryboardIdentifier.StoryBoardID, bundle: nil)
        let identifier = StoryboardIdentifier.GameStats
        let viewController = storyboard.instantiateViewControllerWithIdentifier(
            identifier) as! GameStasticViewController
        return viewController
    }
    
    @IBOutlet weak var totalGamePlayed: UILabel!
    @IBOutlet weak var totalMusicPlayed: UILabel!
    @IBOutlet weak var totalLightFired: UILabel!
    @IBOutlet weak var totalPrefectHit: UILabel!
    @IBOutlet weak var prefectRate: UILabel!
    @IBOutlet weak var totalGameUnlock: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUp()
    }
    
    /// This method calculate data and populate the table
    private func setUp() {
        let totalGamePlayed = GameStats.getTotalGamePlay()
        self.totalGamePlayed.text = String(totalGamePlayed)
        self.totalLightFired.text = String(GameStats.getTotalLightFire())
        self.totalMusicPlayed.text = String(GameStats.getTotalMusicPlayed())
        
        /// load all levels and calculate
        let games = StorageManager.defaultManager.loadAllLevel()
        var totalPrefect:Int = 0
        var totalGameUnlock:Int = 0
        for game in games {
            if game.isUnlock {
                totalGameUnlock++
            }
            if game.bestScore == Constant.fullScore {
                totalPrefect++
            }
        }

        self.totalGameUnlock.text = String(totalGameUnlock)
        self.totalPrefectHit.text = String(totalPrefect)
        let total: Float = Float(totalPrefect) / Float(games.count) * Float(100.0)
        self.prefectRate.text = NSString(format: "%.2f%%", total) as String
    }

    @IBAction func dismissStatsView(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func resetStats(sender: AnyObject) {
        GameStats.reset()
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
