//
//  ViewController.swift
//  Solitaire
//
//  Created by Daniil Sergeyevich Martyn on 4/18/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func NewGame(sender: AnyObject) {
        NSLog("Start New Game")
    }
}

