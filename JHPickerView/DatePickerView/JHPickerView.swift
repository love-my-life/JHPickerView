//
//  JHPickerView.swift
//  JHPickerView
//
//  Created by lailingwei on 16/4/28.
//  Copyright © 2016年 Lijianhui. All rights reserved.
//
//  Github: https://github.com/lJHei/JHPickerView

import UIKit


private let kPickerHeight: CGFloat = 216
private let kToolBarHeight: CGFloat = 44

private let kDismiss_Duration: NSTimeInterval = 0.3
private let kShow_Duration: NSTimeInterval = 0.4

private let kItemColor = UIColor.grayColor()
private let kToolBarColor = UIColor.groupTableViewBackgroundColor()
private let kPickerColor = UIColor.whiteColor()


/**
 Alone类型Picker点击确定回调
 
 - selectedRow: 当前选择的行
 - result:      当前选择行对应的值
 */
typealias PickerTypeAloneDoneHandler = ((selectedRow: Int, result: String) -> Void)

/**
 Date类型Picker点击确定回调
 
 - selectedDate:    当前选择的时间
 - dateString:      当前选择时间对应的字符串
 */
typealias PickerTypeDateDoneHandler = ((selectedDate: NSDate, dateString: String?) -> Void)

/**
 Area类型Picker点击确定回调
 
 - province:    省
 - city:        市
 - district:    区
 */
typealias PickerTypeAreaDoneHandler = ((province: String?, city: String?, district: String?) -> Void)

/**
 Picker点击取消回调
 */
typealias PickerAllCancelHandler = (() -> Void)



/**
 当前控件类型
 
 - Alone:    单列Picker
 - Date:     系统日期Picker
 - Area:     国内地区Picker
 */
@objc private enum JHPickerType: Int {
    case Alone      = 1
    case Date       = 2
    case Area       = 3
}


/**
 地区选择器类型
 
 - ProvinceCityDistrict: 省市区三级
 - ProvinceCity:         省市二级
 */
@objc enum JHAreaType: Int {
    case ProvinceCityDistrict   = 1
    case ProvinceCity           = 2
}


class JHPickerView: UIView {

    // MARK: - Properties
    
    private var pickerType = JHPickerType.Alone
    
    private var contentView = UIView()
    private var pickerView: UIView!
    private var cancelHandler: PickerAllCancelHandler?
    
    
    private var contentBottomConstraint: NSLayoutConstraint!
    private var windowHoriConstraints: [NSLayoutConstraint]?
    private var windowVertConstraints: [NSLayoutConstraint]?
    
    
    /* ********************************************
     @Type: JHPickerType.Alone
     ******************************************** */
    
    private lazy var dataSource: [String] = {
        return [String]()
    }()
    private var selectedRow: Int = 0
    private var selectedResult: String?
    private var aloneTypeDoneHandler: PickerTypeAloneDoneHandler?
    
    
    /* ********************************************
     @Type: JHPickerType.DateMode
     ******************************************** */
    
    private lazy var dateFormatter: NSDateFormatter = {
        return NSDateFormatter()
    }()
    private var datePickerMode: UIDatePickerMode = .Date
    private var dateModeTypeDoneHandler: PickerTypeDateDoneHandler?
    
    
    /* ********************************************
     @Type: JHPickerType.AreaMode
     ******************************************** */
    
    private var areaType: JHAreaType = .ProvinceCityDistrict
    private lazy var areaSource: [[String : AnyObject]] = {
        return [[String : AnyObject]]()
    }()
    private var cities = [[String : AnyObject]]()
    private var districts = [String]()
    private var province: String?
    private var city: String?
    private var district: String?
    private var areaTypeDoneHandler: PickerTypeAreaDoneHandler?
    
    
    
    // MARK: - Life cycle
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(NSStringFromClass(JHPickerView.self)).deinit")
    }
    
    // 配置底层遮罩视图
    private func setupMaskView() {
        
        userInteractionEnabled = true
        
        // Add tap gesture to dismiss Self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(JHPickerView.dismiss))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // 配置内容部分底视图
    private func setupContentViewWithTitle(aTitle: String?) {
        
        contentView.backgroundColor = UIColor.whiteColor()
        let toolBar = setupToolBarWithTitle(aTitle)
        pickerView = setupPickerView()
        
        addSubview(contentView)
        contentView.addSubview(toolBar)
        contentView.addSubview(pickerView)
        
        // add constraints
        contentViewAddConstraints()
        addConstraintsWithToolBar(toolBar, pickerView: pickerView)

    }
    
    // 配置工具条
    private func setupToolBarWithTitle(aTitle: String?) -> UIToolbar {
        
        // space Item
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace,
                                        target: nil,
                                        action: nil)
        
        // Cancel Item
        let leftItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                       target: self,
                                       action: #selector(JHPickerView.dismiss))
        leftItem.tintColor = kItemColor
        
        // Title Item
        let titleItem = UIBarButtonItem(title: aTitle,
                                        style: .Done,
                                        target: nil,
                                        action: nil)
        titleItem.tintColor = kItemColor
        
        
        // Done Item
        let rightItem = UIBarButtonItem(barButtonSystemItem: .Done,
                                        target: self,
                                        action: #selector(JHPickerView.done))
        rightItem.tintColor = kItemColor
        
        
        // ToolBar
        let toolBar = UIToolbar(frame: CGRectZero)
        toolBar.barTintColor = kToolBarColor
        toolBar.items = [leftItem, spaceItem, titleItem, spaceItem, rightItem]
        
        return toolBar
    }
    
    // 配置PickerView
    private func setupPickerView() -> UIView {
    
        var picker: UIView!
        
        switch pickerType {
        case .Date:
            picker = UIDatePicker(frame: CGRectZero)
            (picker as! UIDatePicker).datePickerMode = datePickerMode
            
        default:
            picker = UIPickerView(frame: CGRectZero)
            (picker as! UIPickerView).dataSource = self
            (picker as! UIPickerView).delegate = self
            break
        }
        picker.backgroundColor = kPickerColor
        
        return picker
    }
    
    
    // MARK: - Target actions
    
    func dismiss() {
        
        dismissSelf()
        cancelHandler?()
    }
    
    func done() {
        
        dismissSelf()
        
        switch pickerType {
        case .Alone:
            guard dataSource.count > 0 else {
                print("当前Picker数据源数量为0")
                return
            }
            if let result = selectedResult {
                aloneTypeDoneHandler?(selectedRow: selectedRow, result: result)
            } else {
                aloneTypeDoneHandler?(selectedRow: 0, result: dataSource[0])
            }
        
        case .Area:
            areaTypeDoneHandler?(province: province, city: city, district: district)
        
        case .Date:
            if let datePicker = pickerView as? UIDatePicker {
                dateModeTypeDoneHandler?(selectedDate: datePicker.date, dateString: dateFormatter.stringFromDate(datePicker.date))
            }
        }
        
    }
    
    // MARK: - Helper methods
    
    private func dismissSelf() {
        
        UIView.animateWithDuration(kDismiss_Duration, animations: {
            self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
            self.contentBottomConstraint.constant = kToolBarHeight + kPickerHeight
            self.layoutIfNeeded()
            
        }) { (flag:Bool) in
            if flag {
                self.windowRemoveConstraints()
                self.removeFromSuperview()
            }
        }
    }
    
    
    // MARK: - Helper for constraints
    
    private func contentViewAddConstraints() {
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|",
                                                                             options: .DirectionLeadingToTrailing,
                                                                             metrics: nil,
                                                                             views: ["contentView" : contentView])
        contentBottomConstraint = NSLayoutConstraint(item: contentView,
                                                     attribute: .Bottom,
                                                     relatedBy: .Equal,
                                                     toItem: self,
                                                     attribute: .Bottom,
                                                     multiplier: 1.0,
                                                     constant: 0.0)
        let heightConstraint = NSLayoutConstraint(item: contentView,
                                                  attribute: .Height,
                                                  relatedBy: .Equal,
                                                  toItem: nil,
                                                  attribute: .NotAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: kPickerHeight + kToolBarHeight)
        
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activateConstraints(horiConstraints)
            NSLayoutConstraint.activateConstraints([contentBottomConstraint, heightConstraint])
        } else {
            addConstraints(horiConstraints)
            addConstraint(contentBottomConstraint)
            addConstraint(heightConstraint)
        }
    }
    
    private func windowAddConstraints() {
        
        translatesAutoresizingMaskIntoConstraints = false
        windowHoriConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[self]|",
                                                                               options: .DirectionLeadingToTrailing,
                                                                               metrics: nil,
                                                                               views: ["self" : self])
        windowVertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[self]|",
                                                                               options: .DirectionLeadingToTrailing,
                                                                               metrics: nil,
                                                                               views: ["self" : self])
        if #available(iOS 8.0, *) {
            NSLayoutConstraint.activateConstraints(windowHoriConstraints!)
            NSLayoutConstraint.activateConstraints(windowVertConstraints!)
        } else {
            addConstraints(windowHoriConstraints!)
            addConstraints(windowVertConstraints!)
        }
    }
    
    private func windowRemoveConstraints() {
        
        if let horiConstraints = windowHoriConstraints {
            removeConstraints(horiConstraints)
        }
        if let vertConstraints = windowVertConstraints {
            removeConstraints(vertConstraints)
        }
    }
    
    private func addConstraintsWithToolBar(toolBar: UIToolbar, pickerView: UIView) {
        // ToolBar
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        let horiForToolBarConstrants = NSLayoutConstraint.constraintsWithVisualFormat("H:|[toolBar]|",
                                                                                      options: .DirectionLeadingToTrailing,
                                                                                      metrics: nil,
                                                                                      views: ["toolBar" : toolBar])
        let heightForToolBarConstrant = NSLayoutConstraint(item: toolBar,
                                                           attribute: .Height,
                                                           relatedBy: .Equal,
                                                           toItem: nil,
                                                           attribute: .NotAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: kToolBarHeight)
        // PickerView
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        let horiForPickerConstrants = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pickerView]|",
                                                                                     options: .DirectionLeadingToTrailing,
                                                                                     metrics: nil,
                                                                                     views: ["pickerView" : pickerView])
        let heightForPickerConstrant = NSLayoutConstraint(item: pickerView,
                                                          attribute: .Height,
                                                          relatedBy: .Equal,
                                                          toItem: nil,
                                                          attribute: .NotAnAttribute,
                                                          multiplier: 1.0,
                                                          constant: kPickerHeight)
        
        // Vert
        let vertConstrants = NSLayoutConstraint.constraintsWithVisualFormat("V:|[toolBar][pickerView]|",
                                                                            options: .DirectionLeadingToTrailing,
                                                                            metrics: nil,
                                                                            views: ["toolBar" : toolBar, "pickerView" : pickerView])
        
        contentView.addConstraints(horiForToolBarConstrants)
        contentView.addConstraint(heightForToolBarConstrant)
        contentView.addConstraints(horiForPickerConstrants)
        contentView.addConstraint(heightForPickerConstrant)
        contentView.addConstraints(vertConstrants)
    }

}


// MARK: - UIGesture delegate

extension JHPickerView: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // 确保点击dismiss时，手势区域在有效区域
        guard let touchView = touch.view else {
            return false
        }
        return touchView.isKindOfClass(JHPickerView.self)
    }
}


// MARK: - UIPicker dataSource / delegate

extension JHPickerView: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        
        switch pickerType {
        case .Alone:
            return 1
            
        case .Area:
            return areaType == .ProvinceCityDistrict ? 3 : 2;
            
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch pickerType {
        case .Alone:
            return dataSource.count
            
        case .Area:
            switch areaType {
            case .ProvinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    return areaSource.count
                case 1:
                    // 市
                    return cities.count
                case 2:
                    // 区
                    return districts.count
                default:
                    return 0
                }
                
            case .ProvinceCity:
                switch component {
                case 0:
                    // 省
                    return areaSource.count
                case 1:
                    // 市
                    return cities.count
                default:
                    return 0
                }
            }

        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerType {
        case .Alone:
            return dataSource[row]
            
        case .Area:
            switch areaType {
            case .ProvinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    return areaSource[row]["state"] as? String
                case 1:
                    // 市
                    return cities[row]["city"] as? String
                case 2:
                    // 区
                    return districts[row]
                default:
                    return nil
                }
                
            case .ProvinceCity:
                switch component {
                case 0:
                    // 省
                    return areaSource[row]["state"] as? String
                case 1:
                    // 市
                    return cities[row]["city"] as? String
                default:
                    return nil
                }
            }
            
        default:
            return nil
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerType {
        case .Alone:
            selectedRow = row
            selectedResult = dataSource[row]
            
        case .Area:
            switch areaType {
            case .ProvinceCityDistrict:
                switch component {
                case 0:
                    // 省
                    guard areaSource.count > 0 else {
                        return
                    }
                    province = areaSource[row]["state"] as? String
                    if let theCities = areaSource[row]["cities"] as? [[String : AnyObject]] {
                        cities = theCities
                        city = cities.first?["city"] as? String
                        
                        if let theDistricts = cities.first?["areas"] as? [String] {
                            districts = theDistricts
                            district = theDistricts.first
                        } else {
                            district = nil
                        }
                    } else {
                        city = nil
                        district = nil
                    }
                    pickerView.selectRow(0, inComponent: 1, animated: true)
                    pickerView.reloadComponent(1)
                    pickerView.selectRow(0, inComponent: 2, animated: true)
                    pickerView.reloadComponent(2)
                    
                case 1:
                    // 市
                    guard cities.count > 0 else {
                        return
                    }
                    city = cities[row]["city"] as? String
                    if let theDistricts = cities[row]["areas"] as? [String] {
                        districts = theDistricts
                        district = theDistricts.first
                    } else {
                        district = nil
                    }
                    pickerView.selectRow(0, inComponent: 2, animated: true)
                    pickerView.reloadComponent(2)
                    
                case 2:
                    // 区
                    guard districts.count > 0 else {
                        return
                    }
                    district = districts[row]
                    
                default:
                    break
                }
                
            case .ProvinceCity:
                switch component {
                case 0:
                    // 省
                    guard areaSource.count > 0 else {
                        return
                    }
                    province = areaSource[row]["state"] as? String
                    if let theCities = areaSource[row]["cities"] as? [[String : AnyObject]] {
                        cities = theCities
                        city = cities.first?["city"] as? String
                    } else {
                        city = nil
                    }
                    pickerView.selectRow(0, inComponent: 1, animated: true)
                    pickerView.reloadComponent(1)
                    
                case 1:
                    // 市
                    guard cities.count > 0 else {
                        return
                    }
                    city = cities[row]["city"] as? String
                    
                default:
                    break
                }
            }
            
        default:
            break
        }
    }
    
    
}


// MARK: - ================== Public methods ==================

extension JHPickerView {

    /**
     显示JHPickerView
     */
    func show() {
        
        guard let window = UIApplication.sharedApplication().keyWindow else {
            print("当前window为空")
            return
        }
        
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        window.addSubview(self)
        windowAddConstraints()
        contentBottomConstraint.constant = kPickerHeight + kToolBarHeight
        layoutIfNeeded()
        
        UIView.animateWithDuration(kShow_Duration,
                                   delay: 0.1,
                                   usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: 0.0,
                                   options: .CurveEaseOut,
                                   animations: { 
                                    
                                    self.contentBottomConstraint.constant = 0
                                    self.layoutIfNeeded()
                                    
            }, completion: nil)
    }
    
    
    /**
     取消回调
     */
    func didClickCancelHandler(handler: PickerAllCancelHandler?) {
        cancelHandler = handler
    }
    

}


// MARK: - Alone

extension JHPickerView {

    /**
     初始化一个单列数据的Picker
     
     - parameter dataSource: 数据源
     - parameter title:      标题
     */
    convenience init(aDataSource: [String], aTitle: String?) {
        self.init(frame: CGRectZero)
        
        if aDataSource.count == 0 {
            print("\(NSStringFromClass(JHPickerView.self))数据源数量不应为空")
        }
        
        pickerType = .Alone
        dataSource = aDataSource
        
        setupMaskView()
        setupContentViewWithTitle(aTitle)
    }
    
    /**
     滚动到对应的行
     
     - parameter aRow:     对应的行
     - parameter animated: 是否动画滚动
     */
    func showSelectedRow(aRow: Int, animated: Bool) {
        
        guard pickerType == .Alone else {
            print("当前JHPickerType不为Alone")
            return
        }
        guard dataSource.count > 0 else {
            print("数据源数量不应为空")
            return
        }
        guard aRow >= 0 && aRow < dataSource.count else {
            print("目标row不在数据源数量范围内")
            return
        }
        
        // 更新选择的行和值
        (pickerView as! UIPickerView).selectRow(aRow, inComponent: 0, animated: animated)
        selectedRow = aRow
        selectedResult = dataSource[aRow]
    }
    
    
    /**
     Alone类型Picker点击确定回调
     */
    func didClickDoneForTypeAloneHandler(handler: PickerTypeAloneDoneHandler?) {
        
        guard pickerType == .Alone else {
            print("当前JHPickerType不为Alone")
            return
        }
        aloneTypeDoneHandler = handler
    }
    
}


// MARK: - Date

extension JHPickerView {

    /**
     初始化一个日期Picker
     
     - parameter aDatePickerMode:   日期类型
     - parameter title:             标题
     */
    convenience init(aDatePickerMode: UIDatePickerMode, aTitle: String?) {
        self.init(frame: CGRectZero)
     
        pickerType = .Date
        datePickerMode = aDatePickerMode
        
        setupMaskView()
        setupContentViewWithTitle(aTitle)
    }
    
    /**
     设置当前时间
     */
    func setDate(date: NSDate, animated: Bool) {
        
        guard pickerType == .Date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            picker.setDate(date, animated: animated)
        }
    }
    
    
    func didClickDoneForTypeDateWithFormat(dateFormat: String?, handler: PickerTypeDateDoneHandler?) {
        
        guard pickerType == .Date else {
            print("当前JHPickerType不为Date")
            return
        }
        
        dateFormatter.dateFormat = dateFormat
        dateModeTypeDoneHandler = handler
    }
    
    
    /**
     设置datePicker的最大最小时间  When min > max, the values are ignored. Ignored in countdown timer mode
     
     - parameter minimumDate: 最小时间
     - parameter maximumDate: 最大时间
     */
    func setMinimumDate(minimumDate: NSDate?, maximumDate: NSDate?) {
        
        guard pickerType == .Date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            guard datePickerMode != .CountDownTimer else {
                return
            }
            picker.minimumDate = minimumDate
            picker.maximumDate = maximumDate
        }
    }
    
    
    /**
     设置倒计时
     
     - parameter countDownDuration: for UIDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59
     - parameter minuteInterval:    interval must be evenly divided into 60. default is 1. min is 1, max is 30
     */
    func setCountDownDuration(countDownDuration: NSTimeInterval, minuteInterval: Int) {
        
        guard pickerType == .Date else {
            print("当前Picker并非Date类型，所以无法设置")
            return
        }
        
        if let picker = pickerView as? UIDatePicker {
            guard datePickerMode == .CountDownTimer else {
                return
            }
            picker.countDownDuration = countDownDuration
            picker.minuteInterval = minuteInterval
        }
    }
    
}


// MARK: - Area

extension JHPickerView {

    /**
     初始化一个地区选择器
     
     - parameter anAreaType: 地区选择器目录类型
     - parameter aTitle:     标题
     */
    convenience init(anAreaType: JHAreaType, aTitle: String?) {
        self.init(frame: CGRectZero)
     
        pickerType = .Area
        areaType = anAreaType
        
        // 获取数据
        let fileName = areaType == .ProvinceCityDistrict ? "area1" : "area2"
        print(fileName)
        if let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist") {
            
            areaSource = NSArray(contentsOfFile: filePath) as! [[String : AnyObject]]
            if let theState = areaSource.first {
                
                province = theState["state"] as? String
                if let theCities = theState["cities"] as? [[String : AnyObject]] {
                    
                    cities = theCities
                    if let theCity = theCities.first {
                        
                        city = theCity["city"] as? String
                        if areaType == .ProvinceCityDistrict {
                            if let theDistricts = theCity["areas"] as? [String] {
                                
                                districts = theDistricts
                                district = theDistricts.first
                            }
                        }
                    }
                }
            }
        } else {
            fatalError("没找到地区数据\(fileName)源文件")
        }
        
        setupMaskView()
        setupContentViewWithTitle(aTitle)
    }
    
    
    /**
     Area类型Picker点击确定回调击
     */
    func didClickDoneForTypeAreaHandler(handler: PickerTypeAreaDoneHandler?) {
        
        guard pickerType == .Area else {
            print("当前JHPickerType不为Area")
            return
        }
        areaTypeDoneHandler = handler
    }
    
    
}



















