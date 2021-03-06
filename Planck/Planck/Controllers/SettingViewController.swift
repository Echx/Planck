//
//  SettingViewController.swift
//  Planck
//
//  Created by Wang Jinghan on 07/04/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit

// this controller will handle the setting section, configurate the whole game
class SettingViewController: XViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let settingCellID = "SettingViewCell"
    private let textCellId = "SettingViewTextCell"
    private let sectionTitleForSupport = "support"
    private let sectionTitleForGameCenter = "game center"
    private let sectionTitleForAudio = "audio"
    private let sectionTitleForLevelDesigner = "design"

    private let numOfExtraSection = 2
    private let numOfSectionInTable = 4
    
    private let numOfItemForLevelDesigner = 1
    private let numOfItemForSupport = 3
    private let numOfItemForGameCenter = 3
    private let numOfItemForSetting = 1
    
    private let achievementsIndex = 0
    private let leaderboardIndex = 1
    
    private let sectionIDForLevelDesigner = 0
    private let sectionIDForAudio = 1
    private let sectionIDForGameCenter = 2
    private let sectionIDForSupport = 3
    
    private let headerHeight:CGFloat = 50.0
    private let footerHeight:CGFloat = 20.0
    
    @IBOutlet weak var tableView: UITableView!
    class func getInstance() -> SettingViewController {
        let storyboard = UIStoryboard(name: StoryboardIdentifier.StoryBoardID, bundle: nil)
        let identifier = StoryboardIdentifier.Setting
        let viewController = storyboard.instantiateViewControllerWithIdentifier(identifier)
            as! SettingViewController
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.alwaysBounceVertical = false
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numOfSectionInTable
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == sectionIDForLevelDesigner {
            let cell = tableView.dequeueReusableCellWithIdentifier(textCellId,
                forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = "level designer"
            return cell
        } else if indexPath.section == sectionIDForSupport {
            let cell = tableView.dequeueReusableCellWithIdentifier(textCellId,
                forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = getStaticSupportItems()[indexPath.row]
            return cell
        } else if indexPath.section == sectionIDForGameCenter {
            let cell = tableView.dequeueReusableCellWithIdentifier(textCellId,
                forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = getStaticGameCenterSupportItems()[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(settingCellID,
                forIndexPath: indexPath) as! SettingViewCell
            cell.title.text = "background music"
            cell.toggle.addTarget(self, action: "toggleSetting:",
                forControlEvents: UIControlEvents.TouchUpInside)
            cell.toggle.tag = indexPath.item
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sectionIDForLevelDesigner {
            return numOfItemForLevelDesigner
        } else if section == sectionIDForSupport {
            return numOfItemForSupport
        } else if section == sectionIDForGameCenter {
            return numOfItemForGameCenter
        } else {
            return numOfItemForSetting
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header = UIView(frame: CGRectMake(0, 0, 300, 50))
        let textLabel = UILabel(frame: CGRectMake(5, 5, 300, 40))
        textLabel.text = getSectionHeader(section)
        textLabel.textColor = UIColor(red: 67/255, green: 94/255,
            blue: 118/255, alpha: 1.0)
        textLabel.font = UIFont(name: SystemDefault.planckFont, size: 28.0)
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return footerHeight
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath
        indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let section = indexPath.section
        if section == sectionIDForLevelDesigner {
            let viewController = LevelDesignerViewController.getInstance()
            self.presentViewController(viewController, animated: true, completion: nil)
            // stop playing music
            NSNotificationCenter.defaultCenter().postNotificationName(HomeViewDefaults.stopPlayingKey,
                object: nil)
        } else if section == sectionIDForGameCenter {
            if indexPath.item == achievementsIndex {
                // item 1 : view achievements
                dispatch_async(dispatch_get_main_queue(), {
                    GamiCent.showAchievements(completion: nil)
                })
            } else if indexPath.item == leaderboardIndex {
                // item 2 : view leaderboard
                dispatch_async(dispatch_get_main_queue(), {
                    GamiCent.showLeaderboard(leaderboardID: XGameCenter.leaderboardID,
                        completion: nil)
                })
            } else {
                // item 3 : view statstic
                self.getDrawerController()!.closeDrawerAnimated(true,
                    completion: { (bool) -> Void in
                    let viewController = GameStasticViewController.getInstance()
                    viewController.modalPresentationStyle = .FormSheet
                    self.getDrawerController()!.presentViewController(viewController,
                        animated: true, completion: nil)
                })
            }
        }
    }
    
    func toggleSetting(sender:UIButton!) {
        // better naming pls
        sender.selected = !sender.selected
        if !sender.selected {
            NSNotificationCenter.defaultCenter().postNotificationName(
                HomeViewDefaults.startPlayingKey, object: nil)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(
                HomeViewDefaults.stopPlayingKey, object: nil)
        }
    }
    
    
    private func getSectionHeader(section: Int) -> String? {
        if section == sectionIDForLevelDesigner {
            return sectionTitleForLevelDesigner
        } else if section == sectionIDForAudio {
            return sectionTitleForAudio
        } else if section == sectionIDForSupport {
            return sectionTitleForSupport
        } else {
            return sectionTitleForGameCenter
        }
    }
    
    private func getStaticGameCenterSupportItems() -> [String] {
        var cellItems = ["achievements", "leaderboards", "statistics"]
        return cellItems
    }
    
    private func getStaticSupportItems() -> [String] {
        var cellItems = ["rate us", "credits", "feedback"]
        return cellItems
    }
}
