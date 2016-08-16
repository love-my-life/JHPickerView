//
//  ViewController.swift
//  JHPickerView
//
//  Created by hanchen on 16/8/16.
//  Copyright © 2016年 LiJianhui. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let onePicker: JHPickerView = {
        var dataSource = [String]()
        for i in 0..<20 {
            dataSource.append("\(i)")
        }
        return JHPickerView(aDataSource: dataSource, aTitle: "AlonePicker")
    }()
    private let datePicker: JHPickerView = {
        return JHPickerView(aDatePickerMode: .Date, aTitle: "开始日期")
    }()
    private let areaPicker: JHPickerView = {
        return JHPickerView(anAreaType: .ProvinceCityDistrict, aTitle: "地区选择")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func onePickerBtnAction(sender: UIButton) {
        onePicker.show()
        onePicker.showSelectedRow(3, animated: true)
        onePicker.didClickDoneForTypeAloneHandler { (selectedRow, result) in
            print("selectedRow:\(selectedRow)")
            print("result:\(result)")
            sender.setTitle(result, forState: .Normal)
        }
        onePicker.didClickCancelHandler {
            print("dismiss")
        }
        
    }
    @IBAction func datePickerBtnAction(sender: UIButton) {
        datePicker.show()
        datePicker.setDate(NSDate(), animated: true)
        datePicker.didClickDoneForTypeDateWithFormat("yyy-MM-dd") { (selectedDate, dateString) in
            print("selectedDate:\(selectedDate)")
            print("dateString:\(dateString)")
            sender.setTitle(dateString, forState: .Normal)
        }
        datePicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    @IBAction func areaPickerBtnAction(sender: UIButton) {
        areaPicker.show()
        areaPicker.didClickDoneForTypeAreaHandler { (province, city, district) in
            print("province:\(province)")
            print("city:\(city)")
            print("district:\(district)")
            sender.setTitle(province! + city! + district!, forState: .Normal)
        }
        areaPicker.didClickCancelHandler {
            print("dismiss")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

