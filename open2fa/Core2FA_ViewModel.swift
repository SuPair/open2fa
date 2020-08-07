//
//  Core2FA_ViewModel.swift
//  open2fa
//
//  Created by Vlad Vrublevsky on 05.06.2020.
//  Copyright © 2020 Vlad Vrublevsky. All rights reserved.
//

import Foundation
import SwiftUI
import core_open2fa

class Core2FA_ViewModel: ObservableObject
{
    
    @Published var codes: [code]
    @Published var timeRemaning: Int = 0
    @Published var isActive: Bool = true
    
    private var core: CORE_OPEN2FA
    private var timer: Timer?
    static var needUpdate = false
    static var isLockedByBackground = false
    
    public var isLocked = Binding<Bool>(get: { Core2FA_ViewModel.isLockedByBackground }, set: { Core2FA_ViewModel.isLockedByBackground = $0 })
    
    @objc func updateTime() {
        
        //self.getState()
        
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "ss"
        let time = Int(df.string(from: date))!
        
        if Core2FA_ViewModel.needUpdate {
            self.codes = core.getListOTP()
            Core2FA_ViewModel.needUpdate = false
        }
        
        //Need test! 
        if (time == 0 || time == 30) {
            self.codes = core.getListOTP()
        }
        if time > 30 {
            timeRemaning = 30 - (time - 30)
        } else {
            timeRemaning = 30 - time
        }
        
    }
    
    func deleteService(uuid: UUID) {
        guard core.DeleteCode(id: uuid) == .SUCCEFULL else {
            fatalError("DeleteCode error")
        }
        self.codes.removeAll(where: { $0.id == uuid } )
    }
    
    func DEBUG() {
        _ = core.AddCode(service_name: "Test1", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test2", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test3", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test4", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test5", code: "q4qghrcn2c42bgbz")
        _ = core.AddCode(service_name: "Test6", code: "q4qghrcn2c42bgbz")
    }
    
    func addService(name: String, code: String) -> String? {
        let result = core.AddCode(service_name: name, code: code)
        if result == .SUCCEFULL {
            self.codes = core.getListOTP()
            return nil
        }
        
        switch result {
        case .ALREADY_EXIST:
            return "This name already taken"
        case .CODE_INCORRECT:
            return "This code is incorrect"
        default:
            return "Unknown error"
        }
    }
    
    
    init(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        self.codes = core.getListOTP()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        print("DEBUG: Core2Fa created")
    }
    
    
    init() {
        self.core = CORE_OPEN2FA()
        self.codes = [code(id: UUID(), date: Date(), name: "NULL INIT", codeSingle: "111 111")]
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        print("DEBUG: Core2Fa created")
    }
    
    deinit {
        self.timer = nil
        print("DEBUG: Core2Fa deleted")
    }
    
    func getState() {
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            _debugPrint("inactive")
            self.isActive = false
        } else if state == .active {
            _debugPrint("active")
            self.isActive = true
        }
    }
    
    
    func setObserver() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.willResignActiveNotification, // UIApplication.didBecomeActiveNotification for swift 4.2+
            object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        self.isActive = false
        _debugPrint("applicationDidBecomeActive")
    }
    
    func updateCore(fileURL: URL, pass: String) {
        self.core = CORE_OPEN2FA(fileURL: fileURL, password: pass)
        objectWillChange.send()
        self.codes = core.getListOTP()
        objectWillChange.send()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        self.setObserver()
    }
    
    static func isPasswordCorrect(fileURL: URL, password: String) -> Bool {
        let passcheck = CORE_OPEN2FA.checkPassword(fileURL: fileURL, password: password)
        switch passcheck {
        case .PASS_INCORRECT:
            _debugPrint("PASS_INCORRECT")
            break
        case .FILE_NOT_EXIST:
            _debugPrint("FILE_NOT_EXIST")
            break
        case .CANNOT_DECODE:
            _debugPrint("CANNOT_DECODE")
            break
        case .FILE_UNVIABLE:
            _debugPrint("FILE_UNVIABLE")
            break
        case .NO_CODES:
            _debugPrint("NO_CODES")
            break
        case .SUCCEFULL:
            break
        default:
            _debugPrint("no one")
        }
        return passcheck == .SUCCEFULL || passcheck == .NO_CODES
    }
    
    static func checkFileO2FA(fileURL: URL, password: String) -> FUNC_RESULT {
        return CORE_OPEN2FA.checkPassword(fileURL: fileURL, password: password)
    }
    
}
