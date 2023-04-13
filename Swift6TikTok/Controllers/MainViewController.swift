//
//  MainViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/09/28.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var plusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func startAction(_ sender: Any) {
        performSegue(withIdentifier: "startSegue", sender: nil)
    }
    

}
