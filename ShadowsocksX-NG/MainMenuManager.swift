//
//  MainMenuManager.swift
//  ShadowsocksX-NG
//
//  Created by ParadiseDuo on 2020/4/18.
//  Copyright © 2020 qiuyuzhou. All rights reserved.
//

import Cocoa

class MainMenuManager: NSObject, NSUserNotificationCenterDelegate {
    // MARK: Controllers
    var qrcodeWinCtrl: SWBQRCodeWindowController!
    var preferencesWinCtrl: PreferencesWindowController!
    var advPreferencesWinCtrl: AdvPreferencesWindowController!
    var proxyPreferencesWinCtrl: ProxyPreferencesController!
    var editUserRulesWinCtrl: UserRulesController!
    var httpPreferencesWinCtrl : HTTPPreferencesWindowController!
    var subscribePreferenceWinCtrl: SubscribePreferenceWindowController!
    var toastWindowCtrl: ToastWindowController!
    var timeInteravalPreferencesWinCtrl : TimeInteravalPreferencesWindowController!
    
    var launchAtLoginController: LaunchAtLoginController = LaunchAtLoginController()
    
    // MARK: Outlets
    @IBOutlet weak var statusMenu: NSMenu!
    
    @IBOutlet weak var runningStatusMenuItem: NSMenuItem!
    @IBOutlet weak var toggleRunningMenuItem: NSMenuItem!
    @IBOutlet weak var proxyMenuItem: NSMenuItem!
    @IBOutlet weak var autoModeMenuItem: NSMenuItem!
    @IBOutlet weak var globalModeMenuItem: NSMenuItem!
    @IBOutlet weak var manualModeMenuItem: NSMenuItem!
    @IBOutlet weak var whiteListModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLAutoModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLBackChinaMenuItem: NSMenuItem!
    
    @IBOutlet weak var serversMenuItem: NSMenuItem!
    @IBOutlet var connectionDelayTestMenuItem: NSMenuItem!
    @IBOutlet var showQRCodeMenuItem: NSMenuItem!
    @IBOutlet var scanQRCodeMenuItem: NSMenuItem!
    @IBOutlet var showBunchJsonExampleFileItem: NSMenuItem!
    @IBOutlet var importBunchJsonFileItem: NSMenuItem!
    @IBOutlet var exportAllServerProfileItem: NSMenuItem!
    @IBOutlet var serversPreferencesMenuItem: NSMenuItem!
    
    @IBOutlet var copyHttpProxyExportCmdLineMenuItem: NSMenuItem!
    
    @IBOutlet weak var lanchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var connectAtLaunchMenuItem: NSMenuItem!
    @IBOutlet weak var ShowNetworkSpeedItem: NSMenuItem!
    @IBOutlet weak var checkUpdateMenuItem: NSMenuItem!
    @IBOutlet weak var checkUpdateAtLaunchMenuItem: NSMenuItem!
    @IBOutlet var updateSubscribeAtLaunchMenuItem: NSMenuItem!
    @IBOutlet var manualUpdateSubscribeMenuItem: NSMenuItem!
    @IBOutlet var editSubscribeMenuItem: NSMenuItem!
    
    @IBOutlet weak var copyCommandLine: NSMenuItem!
    
    @IBOutlet weak var icmpMenuItem: NSMenuItem!
    @IBOutlet weak var tcpMenuItem: NSMenuItem!
    
    @IBOutlet weak var ascendingMenuItem: NSMenuItem!
    
    // MARK: Variables
    var statusItemView:StatusItemView!
    var statusItem: NSStatusItem?
    var speedMonitor:NetSpeedMonitor?
    var globalSubscribeFeed: Subscribe!
    
    var speedTimer:Timer?
    let repeatTimeinterval: TimeInterval = 2.0
    
    var autoPingTimer: Timer?
    var autoUpdateSubscribesTimer: Timer?
    
    override func awakeFromNib() {
        NSUserNotificationCenter.default.delegate = self
        // Prepare ss-local
        InstallSSLocal { (s) in
            InstallPrivoxy { (ss) in
                ProxyConfHelper.install()
            }
        }
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            USERDEFAULTS_SHADOWSOCKS_ON: true,
            USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE: "auto",
            USERDEFAULTS_LOCAL_SOCKS5_LISTEN_PORT: NSNumber(value: 1086 as UInt16),
            USERDEFAULTS_LOCAL_SOCKS5_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_PAC_SERVER_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_PAC_SERVER_LISTEN_PORT:NSNumber(value: 8090 as UInt16),
            USERDEFAULTS_LOCAL_SOCKS5_TIMEOUT: NSNumber(value: 60 as UInt),
            USERDEFAULTS_LOCAL_SOCKS5_ENABLE_UDP_RELAY: NSNumber(value: false as Bool),
            USERDEFAULTS_LOCAL_SOCKS5_ENABLE_VERBOSE_MODE: NSNumber(value: false as Bool),
            USERDEFAULTS_GFW_LIST_URL: "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
            USERDEFAULTS_ACL_WHITE_LIST_URL: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/banAD.acl",
            USERDEFAULTS_ACL_AUTO_LIST_URL: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/gfwlist-banAD.acl",
            USERDEFAULTS_ACL_PROXY_BACK_CHN_URL:"https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/backcn-banAD.acl",
            USERDEFAULTS_AUTO_CONFIGURE_NETWORK_SERVICES: NSNumber(value: true as Bool),
            USERDEFAULTS_LOCAL_HTTP_LISTEN_ADDRESS: "127.0.0.1",
            USERDEFAULTS_LOCAL_HTTP_LISTEN_PORT: NSNumber(value: 1087 as UInt16),
            USERDEFAULTS_LOCAL_HTTP_ON: true,
            USERDEFAULTS_LOCAL_HTTP_FOLLOW_GLOBAL: true,
            USERDEFAULTS_AUTO_CHECK_UPDATE: false,
            USERDEFAULTS_ACL_FILE_NAME: "chn.acl",
            USERDEFAULTS_SUBSCRIBES: [],
            USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE:false,
            USERDEFAULTS_AUTO_DELAY_TEST: false,
            USERDEFAULTS_TIME_INTERAVAL_DALAY_TEST_ENABLE: true,
            USERDEFAULTS_TIME_INTERAVAL_SUBSCRIBE_UPDATE_ENABLE: true,
            USERDEFAULTS_TIME_INTERAVAL_DALAY_TEST_TIME: NSNumber(value: 30 as UInt16),
            USERDEFAULTS_TIME_INTERAVAL_SUBSCRIBE_UPDATE_TIME: NSNumber(value: 3 as UInt16)
        ])
        
        let notifyCenter = NotificationCenter.default
        notifyCenter.addObserver(forName: NOTIFY_ADV_PROXY_CONF_CHANGED, object: nil, queue: nil) { (noti) in
            self.applyConfig { (s) in
                self.updateCopyHttpProxyExportMenu()
            }
        }
        notifyCenter.addObserver(forName: NOTIFY_SERVER_PROFILES_CHANGED, object: nil, queue: nil) { (noti) in
            let profileMgr = ServerProfileManager.instance
            if profileMgr.getActiveProfileId() == "" &&
                profileMgr.profiles.count > 0{
                if profileMgr.profiles[0].isValid(){
                    profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
                }
            }
            SyncSSLocal { (suce) in
                self.updateServersMenu()
                self.updateMainMenu()
                self.updateRunningModeMenu()
            }
        }
        notifyCenter.addObserver(forName: NOTIFY_ADV_CONF_CHANGED, object: nil, queue: nil) { (noti) in
            SyncSSLocal { (suce) in
                self.applyConfig { (s) in
                    
                }
            }
        }
        notifyCenter.addObserver(forName: NOTIFY_HTTP_CONF_CHANGED, object: nil, queue: nil) { (noti) in
            SyncPrivoxy {
                self.applyConfig { (s) in
                    
                }
            }
            
        }
        notifyCenter.addObserver(forName: NOTIFY_FOUND_SS_URL, object: nil, queue: nil) { (noti: Notification) in
            self.foundSSRURL(noti)
        }
        notifyCenter.addObserver(forName: NOTIFY_UPDATE_MAINMENU, object: nil, queue: OperationQueue.main) { (noti) in
            self.updateServersMenu()
            self.updateRunningModeMenu()
        }
        notifyCenter.addObserver(forName: NOTIFY_TOGGLE_RUNNING, object: nil, queue: OperationQueue.main) { (noti) in
            self.toggle { (suc) in
                
            }
        }
        
        DispatchQueue.main.async {
            self.setUpMenu(defaults.bool(forKey: USERDEFAULTS_ENABLE_SHOW_SPEED))
            self.updateMainMenu()
            self.updateCopyHttpProxyExportMenu()
            self.updateServersMenu()
            self.updateRunningModeMenu()
            self.updateLaunchAtLoginMenu()
            
            if defaults.bool(forKey: USERDEFAULTS_CONNECT_AT_LAUNCH) && ServerProfileManager.instance.getActiveProfileId() != "" {
                defaults.set(false, forKey: USERDEFAULTS_SHADOWSOCKS_ON)
                defaults.synchronize()
                self.toggle { (suc) in
                    self.updateSubAndVersion()
                }
            } else {
                self.updateSubAndVersion()
            }
            
            // 自动测试延迟
            self.timingTestDelay()
            
            // 添加自动更新订阅定时器
            self.timingUpdateSubscribes()
            
            notifyCenter.addObserver(forName: NOTIFY_TIME_INTERAVAL_DELAY_CHANGED, object: nil, queue: nil) { (note: Notification) in
                self.timingTestDelay()
            }
            
            notifyCenter.addObserver(forName: NOTIFY_TIME_INTERAVAL_SUBSCRIBE_CHANGED, object: nil, queue: nil) { (note: Notification) in
                self.timingUpdateSubscribes(reset: (note.object) as? Bool ?? true)
            }
        }
    }
    
    @objc private func updateSubAndVersion() {
        DispatchQueue.global(qos: .userInteractive).async {
            // Version Check!
            if UserDefaults.standard.bool(forKey: USERDEFAULTS_AUTO_CHECK_UPDATE) {
                self.checkForUpdate(mustShowAlert: false)
            }
            if UserDefaults.standard.bool(forKey: USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE) {
                SubscribeManager.instance.updateAllServerFromSubscribe(auto: true)
            }
        }
    }
    
    // MARK: Mainmenu functions
    
    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        self.toggle { (s) in
            
        }
    }
    
    private func toggle(finish: @escaping(_ success: Bool)->()) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: USERDEFAULTS_SHADOWSOCKS_ON), forKey: USERDEFAULTS_SHADOWSOCKS_ON)
        defaults.synchronize()
        self.applyConfig { (suc) in
            SyncSSLocal { (s) in
                DispatchQueue.main.async {
                    self.updateMainMenu()
                    finish(true)
                }
            }
        }
    }
    
    @IBAction func updateGFWList(_ sender: NSMenuItem) {
        UpdatePACFromGFWList()
    }
    
    @IBAction func updateWhiteList(_ sender: NSMenuItem) {
        UpdateACL()
    }
    
    @IBAction func editUserRulesForPAC(_ sender: NSMenuItem) {
        if editUserRulesWinCtrl != nil {
            editUserRulesWinCtrl.close()
        }
        let ctrl = UserRulesController(windowNibName: "UserRulesController")
        editUserRulesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editSubscribeFeed(_ sender: NSMenuItem) {
        if subscribePreferenceWinCtrl != nil {
            subscribePreferenceWinCtrl.close()
        }
        let ctrl = SubscribePreferenceWindowController(windowNibName: "SubscribePreferenceWindowController")
        subscribePreferenceWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func toggleLaunghAtLogin(_ sender: NSMenuItem) {
        let bFlag = !launchAtLoginController.launchAtLogin;
        launchAtLoginController.launchAtLogin = bFlag;
        lanchAtLoginMenuItem.state = NSControl.StateValue(rawValue: bFlag ? 1 : 0)
    }
    
    @IBAction func toggleConnectAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: USERDEFAULTS_CONNECT_AT_LAUNCH), forKey: USERDEFAULTS_CONNECT_AT_LAUNCH)
        defaults.synchronize()
        updateMainMenu()
    }
    
    
    @IBAction func toggleCopyCommandLine(_ sender: NSMenuItem) {
        // Get the Http proxy config.
        let defaults = UserDefaults.standard
        let address = defaults.string(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_ADDRESS)
        let port = defaults.integer(forKey: USERDEFAULTS_LOCAL_HTTP_LISTEN_PORT)
        
        if let a = address {
            let command = "export http_proxy=http://\(a):\(port);export https_proxy=http://\(a):\(port);"
            
            // Copy to paste board.
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)
            
            // Show a toast notification.
            self.makeToast("Export Command Copied.".localized)
        } else {
            self.makeToast("Export Command Copied Failed.".localized)
        }
    }
    
    // MARK: Server submenu function
    
    @IBAction func showQRCodeForCurrentServer(_ sender: NSMenuItem) {
        var errMsg: String?
        if let profile = ServerProfileManager.instance.getActiveProfile() {
            if profile.isValid() {
                // Show window
                DispatchQueue.main.async {
                    if self.qrcodeWinCtrl != nil{
                        self.qrcodeWinCtrl.close()
                    }
                    self.qrcodeWinCtrl = SWBQRCodeWindowController(windowNibName: "SWBQRCodeWindowController")
                    self.qrcodeWinCtrl.qrCode = profile.getSSRURL()!.absoluteString
                    self.qrcodeWinCtrl.title = profile.title()
                    self.qrcodeWinCtrl.showWindow(self)
                    NSApp.activate(ignoringOtherApps: true)
                    self.qrcodeWinCtrl.window?.makeKeyAndOrderFront(nil)
                }
                return
            } else {
                errMsg = "Current server profile is not valid.".localized
            }
        } else {
            errMsg = "No current server profile.".localized
        }
        let userNote = NSUserNotification()
        userNote.title = errMsg
        userNote.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(userNote);
    }
    
    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        ScanQRCodeOnScreen()
    }
    
    @IBAction func importProfileURLFromPasteboard(_ sender: NSMenuItem) {
        let pb = NSPasteboard.general
        if #available(OSX 10.13, *) {
            if let text = pb.string(forType: NSPasteboard.PasteboardType.URL) {
                if let url = URL(string: text) {
                    NotificationCenter.default.post(
                        name: NOTIFY_FOUND_SS_URL, object: nil
                        , userInfo: [
                            "urls": [url],
                            "source": "pasteboard",
                    ])
                }
            }
        }
        if let text = pb.string(forType: NSPasteboard.PasteboardType.string) {
            var urls = text.components(separatedBy: CharacterSet(charactersIn: "\n,"))
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .map { URL(string: $0) }
                .filter { $0 != nil }
                .map { $0! }
            urls = urls.filter { $0.scheme == "ssr" || $0.scheme == "ss" }
            
            NotificationCenter.default.post(
                name: NOTIFY_FOUND_SS_URL, object: nil
                , userInfo: [
                    "urls": urls,
                    "source": "pasteboard",
            ])
        }
    }
    
    @IBAction func showBunchJsonExampleFile(_ sender: NSMenuItem) {
        ServerProfileManager.showExampleConfigFile()
    }
    
    @IBAction func importBunchJsonFile(_ sender: NSMenuItem) {
        ServerProfileManager.instance.importConfigFile()
    }
    
    @IBAction func exportAllServerProfile(_ sender: NSMenuItem) {
        ServerProfileManager.instance.exportConfigFile()
    }
    
    @IBAction func updateSubscribe(_ sender: NSMenuItem) {
        SubscribeManager.instance.updateAllServerFromSubscribe(auto: false)
    }
    
    @IBAction func updateSubscribeAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE), forKey: USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE)
        defaults.synchronize()
        updateSubscribeAtLaunchMenuItem.state = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE) ? 1 : 0)
    }
    
    
    // MARK: Proxy submenu function
    
    @IBAction func selectPACMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("auto", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func selectGlobalMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("global", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func selectManualMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("manual", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func selectACLAutoMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("gfwlist.acl", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func selectACLBackCHNMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("backchn.acl", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func selectWhiteListMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        defaults.setValue("chn.acl", forKey: USERDEFAULTS_ACL_FILE_NAME)
        defaults.synchronize()
        SyncSSLocal { (suce) in
            self.applyConfig { (suc) in
                self.updateRunningModeMenu()
            }
        }
    }
    
    @IBAction func editServerPreferences(_ sender: NSMenuItem) {
        if preferencesWinCtrl != nil {
            preferencesWinCtrl.close()
        }
        let ctrl = PreferencesWindowController(windowNibName: "PreferencesWindowController")
        preferencesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editAdvPreferences(_ sender: NSMenuItem) {
        if advPreferencesWinCtrl != nil {
            advPreferencesWinCtrl.close()
        }
        let ctrl = AdvPreferencesWindowController(windowNibName: "AdvPreferencesWindowController")
        advPreferencesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editHTTPPreferences(_ sender: NSMenuItem) {
        if httpPreferencesWinCtrl != nil {
            httpPreferencesWinCtrl.close()
        }
        let ctrl = HTTPPreferencesWindowController(windowNibName: "HTTPPreferencesWindowController")
        httpPreferencesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editTimeInteravalPreferences(_ sender: NSMenuItem) {
        if timeInteravalPreferencesWinCtrl != nil {
            timeInteravalPreferencesWinCtrl.close()
        }
        let ctrl = TimeInteravalPreferencesWindowController(windowNibName: "TimeInteravalPreferencesWindowController")
        timeInteravalPreferencesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editProxyPreferences(_ sender: NSMenuItem) {
        if proxyPreferencesWinCtrl != nil {
            proxyPreferencesWinCtrl.close()
        }
        let ctrl = ProxyPreferencesController(windowNibName: "ProxyPreferencesController")
        proxyPreferencesWinCtrl = ctrl
        
        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func selectServer(_ sender: NSMenuItem) {
        let index = sender.tag
        let spMgr = ServerProfileManager.instance
        let newProfile = spMgr.profiles[index]
        if newProfile.uuid != spMgr.getActiveProfileId() {
            spMgr.setActiveProfiledId(newProfile.uuid)
            SyncSSLocal { (suce) in
                self.updateServersMenu()
                self.updateRunningModeMenu()
            }
        } else {
            updateRunningModeMenu()
        }
    }
    
    @IBAction func connectionDelayTest(_ sender: NSMenuItem) {
        ConnectTestigManager.start()
    }
    
    @IBAction func ascendingDelay(_ sender: NSMenuItem) {
        if sender.state.rawValue == 0 {
            sender.state = NSControl.StateValue(rawValue: 1)
            UserDefaults.standard.set(true, forKey: USERDEFAULTS_ASCENDING_DELAY)
            self.updateServersMenu()
        } else {
            sender.state = NSControl.StateValue(rawValue: 0)
            UserDefaults.standard.set(false, forKey: USERDEFAULTS_ASCENDING_DELAY)
        }
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func doPingTest(_ sender: NSMenuItem) {
        icmpMenuItem.state = NSControl.StateValue(rawValue: 1)
        tcpMenuItem.state = NSControl.StateValue(rawValue: 0)
        UserDefaults.standard.set(false, forKey: USERDEFAULTS_TCP)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func doTcpingTest(_ sender: NSMenuItem) {
        icmpMenuItem.state = NSControl.StateValue(rawValue: 0)
        tcpMenuItem.state = NSControl.StateValue(rawValue: 1)
        UserDefaults.standard.set(true, forKey: USERDEFAULTS_TCP)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func showSpeedTap(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        var enable = defaults.bool(forKey: USERDEFAULTS_ENABLE_SHOW_SPEED)
        enable = !enable
        setUpMenu(enable)
        defaults.set(enable, forKey: USERDEFAULTS_ENABLE_SHOW_SPEED)
        defaults.synchronize()
        updateMainMenu()
    }
    
    @IBAction func showLogs(_ sender: NSMenuItem) {
        let ws = NSWorkspace.shared
        if let appUrl = ws.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            try! ws.launchApplication(at: appUrl
                ,options: NSWorkspace.LaunchOptions.default
                ,configuration: [NSWorkspace.LaunchConfigurationKey.arguments: "~/Library/Logs/ss-local.log"])
        }
    }
    
    
    @IBAction func feedback(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://github.com/wzdnzd/ShadowsocksX-NG-R/issues")!)
    }
    
    @IBAction func checkForUpdate(_ sender: NSMenuItem) {
        checkForUpdate(mustShowAlert: true)
    }
    
    @IBAction func checkUpdatesAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: USERDEFAULTS_AUTO_CHECK_UPDATE), forKey: USERDEFAULTS_AUTO_CHECK_UPDATE)
        defaults.synchronize()
        checkUpdateAtLaunchMenuItem.state = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_AUTO_CHECK_UPDATE) ? 1 : 0)
    }
    
    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateLaunchAtLoginMenu() {
        lanchAtLoginMenuItem.state = NSControl.StateValue(rawValue: launchAtLoginController.launchAtLogin ? 1 : 0)
    }
    
    func updateRunningModeMenu() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        var serverMenuText = "Servers".localized
        
        let mgr = ServerProfileManager.instance
        for p in mgr.profiles {
            if mgr.getActiveProfileId() == p.uuid {
                if !p.remark.isEmpty {
                    serverMenuText = p.remark
                } else {
                    serverMenuText = p.serverHost
                }
                if p.latency.doubleValue != Double.infinity {
                    serverMenuText += "  - \(NumberFormatter.three(p.latency)) ms"
                }
                else{
                    if !neverSpeedTestBefore {
                        serverMenuText += "  - failed"
                    }
                }
            }
        }
        
        serversMenuItem.title = serverMenuText
        autoModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        globalModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        manualModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        whiteListModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLBackChinaMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLAutoModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        if mode == "auto" {
            autoModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "global" {
            globalModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "manual" {
            manualModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "whiteList" {
            let aclMode = defaults.string(forKey: USERDEFAULTS_ACL_FILE_NAME)!
            switch aclMode {
            case "backchn.acl":
                ACLModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLBackChinaMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLModeMenuItem.title = "Proxy Back China".localized
                break
            case "gfwlist.acl":
                ACLModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLAutoModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLModeMenuItem.title = "ACL Auto".localized
                break
            default:
                whiteListModeMenuItem.state = NSControl.StateValue(rawValue: 1)
            }
        }
        updateStatusItemUI()
    }
    
    func updateStatusItemUI() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        if !defaults.bool(forKey: USERDEFAULTS_SHADOWSOCKS_ON) {
            return
        }
        let titleWidth:CGFloat = 0
        let imageWidth:CGFloat = 22
        if statusItemView != nil {
            statusItemView.setIconWith(mode: mode)
        } else {
            statusItem?.length = titleWidth + imageWidth
        }
    }
    
    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_SHADOWSOCKS_ON)
        if isOn {
            runningStatusMenuItem.title = "Shadowsocks: On".localized
            runningStatusMenuItem.image = NSImage(named: NSImage.statusAvailableName)
            toggleRunningMenuItem.title = "Turn Shadowsocks Off".localized
            copyCommandLine.isHidden = false
            updateStatusItemUI()
        } else {
            runningStatusMenuItem.title = "Shadowsocks: Off".localized
            runningStatusMenuItem.image = NSImage(named: NSImage.statusUnavailableName)
            toggleRunningMenuItem.title = "Turn Shadowsocks On".localized
            copyCommandLine.isHidden = true
            if statusItemView != nil {
                statusItemView.setIconWith(mode: "disabled")
            }
        }
        if defaults.bool(forKey: USERDEFAULTS_TCP) {
            icmpMenuItem.state = NSControl.StateValue(rawValue: 0)
            tcpMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else {
            icmpMenuItem.state = NSControl.StateValue(rawValue: 1)
            tcpMenuItem.state = NSControl.StateValue(rawValue: 0)
        }
        ShowNetworkSpeedItem.state          = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_ENABLE_SHOW_SPEED) ? 1 : 0)
        connectAtLaunchMenuItem.state       = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_CONNECT_AT_LAUNCH)  ? 1 : 0)
        checkUpdateAtLaunchMenuItem.state   = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_AUTO_CHECK_UPDATE)  ? 1 : 0)
        ascendingMenuItem.state             = NSControl.StateValue(rawValue: defaults.bool(forKey: USERDEFAULTS_ASCENDING_DELAY)  ? 1 : 0)
    }
    
    func updateCopyHttpProxyExportMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_LOCAL_HTTP_ON)
        copyHttpProxyExportCmdLineMenuItem.isHidden = !isOn
    }
    
    //TODO:https://git.codingcafe.org/Mirrors/shadowsocks/ShadowsocksX-NG/blob/master/ShadowsocksX-NG/AppDelegate.swift
    func updateServersMenu() {
        let mgr = ServerProfileManager.instance
        serversMenuItem.submenu?.removeAllItems()
        let showQRItem = showQRCodeMenuItem
        let scanQRItem = scanQRCodeMenuItem
        let preferencesItem = serversPreferencesMenuItem
        let showBunch = showBunchJsonExampleFileItem
        let importBuntch = importBunchJsonFileItem
        let exportAllServer = exportAllServerProfileItem
        let updateSubscribeItem = manualUpdateSubscribeMenuItem
        let autoUpdateSubscribeItem = updateSubscribeAtLaunchMenuItem
        let editSubscribeItem = editSubscribeMenuItem
        let copyHttpProxyExportCmdLineItem = copyHttpProxyExportCmdLineMenuItem
        
        serversMenuItem.submenu?.addItem(editSubscribeItem!)
        serversMenuItem.submenu?.addItem(autoUpdateSubscribeItem!)
        autoUpdateSubscribeItem?.state = NSControl.StateValue(rawValue: UserDefaults.standard.bool(forKey: USERDEFAULTS_AUTO_UPDATE_SUBSCRIBE) ? 1 : 0)
        serversMenuItem.submenu?.addItem(updateSubscribeItem!)
        serversMenuItem.submenu?.addItem(showQRItem!)
        serversMenuItem.submenu?.addItem(scanQRItem!)
        serversMenuItem.submenu?.addItem(copyHttpProxyExportCmdLineItem!)
        serversMenuItem.submenu?.addItem(showBunch!)
        serversMenuItem.submenu?.addItem(importBuntch!)
        serversMenuItem.submenu?.addItem(exportAllServer!)
        serversMenuItem.submenu?.addItem(NSMenuItem.separator())
        serversMenuItem.submenu?.addItem(preferencesItem!)
        
        if !mgr.profiles.isEmpty {
            serversMenuItem.submenu?.addItem(NSMenuItem.separator())
        }
        
        var i = 0
        var serverMenuItems = [NSMenuItem]()
        var fastTime = ""
        if let t = UserDefaults.standard.object(forKey: USERDEFAULTS_FASTEST_NODE) as? String {
            fastTime = t
        }
        if !neverSpeedTestBefore && UserDefaults.standard.bool(forKey: USERDEFAULTS_ASCENDING_DELAY) {
            mgr.profiles = mgr.profiles.sorted { (p1, p2) -> Bool in
                return p1.latency.doubleValue <= p2.latency.doubleValue
            }
        }
        for p in mgr.profiles {
            let item = NSMenuItem()
            item.tag = i //+ kProfileMenuItemIndexBase
            item.title = p.title()
            let latency = p.latency
            let nf = NumberFormatter.three(latency)
            if latency.doubleValue != Double.infinity {
                item.title += "  - \(nf) ms"
                if nf == fastTime {
                    let dic = [NSAttributedString.Key.foregroundColor : NSColor.green]
                    let attStr = NSAttributedString(string: item.title, attributes: dic)
                    item.attributedTitle = attStr
                }
            }else{
                if !neverSpeedTestBefore {
                    item.title += "  - failed"
                    let dic = [NSAttributedString.Key.foregroundColor : NSColor.red]
                    let attStr = NSAttributedString(string: item.title, attributes: dic)
                    item.attributedTitle = attStr
                }
            }
            if mgr.getActiveProfileId() == p.uuid {
                item.state = NSControl.StateValue(rawValue: 1)
            }
            if !p.isValid() {
                item.isEnabled = false
            }
            
            item.action = #selector(MainMenuManager.selectServer)
            
            if !p.ssrGroup.isEmpty {
                if((serversMenuItem.submenu?.item(withTitle: p.ssrGroup)) == nil){
                    let groupSubmenu = NSMenu()
                    let groupSubmenuItem = NSMenuItem()
                    groupSubmenuItem.title = p.ssrGroup
                    serversMenuItem.submenu?.addItem(groupSubmenuItem)
                    serversMenuItem.submenu?.setSubmenu(groupSubmenu, for: groupSubmenuItem)
                    if mgr.getActiveProfileId() == p.uuid {
                        item.state = NSControl.StateValue(rawValue: 1)
                        groupSubmenuItem.state = NSControl.StateValue(rawValue: 1)
                    }
                    groupSubmenuItem.submenu?.addItem(item)
                    i += 1
                    continue
                }
                else{
                    if mgr.getActiveProfileId() == p.uuid {
                        item.state = NSControl.StateValue(rawValue: 1)
                        serversMenuItem.submenu?.item(withTitle: p.ssrGroup)?.state = NSControl.StateValue(rawValue: 1)
                    }
                    serversMenuItem.submenu?.item(withTitle: p.ssrGroup)?.submenu?.addItem(item)
                    i += 1
                    continue
                }
            }
            
            serverMenuItems.append(item)
            i += 1
        }
        // 把没有分组的放到最下面，如果有100个服务器的时候对用户很有用
        for item in serverMenuItems {
            serversMenuItem.submenu?.addItem(item)
        }
    }
    
    func setUpMenu(_ showSpeed:Bool){
        // should not operate the system status bar
        // we can add sub menu like bittorrent sync
        if statusItem == nil{
            statusItem = NSStatusBar.system.statusItem(withLength: 85)
            let image = NSImage(named: "menu_icon")
            image?.isTemplate = true
            statusItem?.image = image
            statusItemView = StatusItemView(statusItem: statusItem!, menu: statusMenu)
            statusItem!.view = statusItemView
        }
        statusItemView.showSpeed = showSpeed
        if showSpeed{
            if speedMonitor == nil{
                speedMonitor = NetSpeedMonitor()
            }
            statusItem?.length = 85
            speedTimer = Timer.scheduledTimer(withTimeInterval: repeatTimeinterval, repeats: true, block: {[weak self] (timer) in
                guard let w = self else {return}
                w.speedMonitor?.timeInterval(w.repeatTimeinterval, downloadAndUploadSpeed: { (down, up) in
                    w.statusItemView.setRateData(up: Float(up), down: Float(down))
                })
            })
        }else{
            speedTimer?.invalidate()
            speedTimer = nil
            speedMonitor = nil
            statusItem?.length = 20
        }
    }
    
    func checkForUpdate(mustShowAlert: Bool) -> Void {
        let versionChecker = VersionChecker()
        DispatchQueue.global().async {
            let newVersion = versionChecker.checkNewVersion()
            DispatchQueue.main.async {
                if (mustShowAlert || newVersion["newVersion"] as! Bool){
                    let alertResult = versionChecker.showAlertView(Title: newVersion["Title"] as! String, SubTitle: newVersion["SubTitle"] as! String, ConfirmBtn: newVersion["ConfirmBtn"] as! String, CancelBtn: newVersion["CancelBtn"] as! String)
                    if (newVersion["newVersion"] as! Bool && alertResult == 1000){
                        NSWorkspace.shared.open(URL(string: "https://github.com/wzdnzd/ShadowsocksX-NG-R/releases")!)
                    }
                }
            }
        }
    }
    
    private func foundSSRURL(_ note: Notification) {
        if let userInfo = (note as NSNotification).userInfo {
            let urls: [URL] = userInfo["urls"] as! [URL]
            
            let mgr = ServerProfileManager.instance
            var isChanged = false
            
            for url in urls {
                let profielDict = ParseAppURLSchemes(url)//ParseSSURL(url)
                if let profielDict = profielDict {
                    let profile = ServerProfile.fromDictionary(profielDict as [String : AnyObject])
                    mgr.profiles.append(profile)
                    isChanged = true
                    
                    let userNote = NSUserNotification()
                    userNote.title = "Add Shadowsocks Server Profile".localized
                    if userInfo["source"] as! String == "qrcode" {
                        userNote.subtitle = "By scan QR Code".localized
                    } else if userInfo["source"] as! String == "url" {
                        userNote.subtitle = "By Handle SS URL".localized
                    }
                    userNote.informativeText = "Host: \(profile.serverHost)\n Port: \(profile.serverPort)\n Encription Method: \(profile.method)".localized
                    userNote.soundName = NSUserNotificationDefaultSoundName
                    
                    NSUserNotificationCenter.default.deliver(userNote);
                }else{
                    let userNote = NSUserNotification()
                    userNote.title = "Failed to Add Server Profile".localized
                    userNote.subtitle = "Address can not be recognized".localized
                    NSUserNotificationCenter.default.deliver(userNote);
                }
            }
            if isChanged {
                mgr.save()
                self.updateServersMenu()
            }
        }
    }
    
    private func timingTestDelay() {
        let defaults = UserDefaults.standard
        let enable = defaults.bool(forKey: USERDEFAULTS_TIME_INTERAVAL_DALAY_TEST_ENABLE)
        
        if enable {
            if autoPingTimer != nil {
                autoPingTimer?.invalidate()
            }
            
            autoPingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(defaults.integer(forKey: USERDEFAULTS_TIME_INTERAVAL_DALAY_TEST_TIME) * 60), repeats: true) { timer in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ConnectTestigManager.start(inform: false)
                }
            }
        } else {
            autoPingTimer?.invalidate()
        }
    }
    
    private func timingUpdateSubscribes(reset: Bool=true) {
        if autoUpdateSubscribesTimer != nil && !reset {
            return
        }
        
        let defaults = UserDefaults.standard
        let instance = SubscribeManager.instance
        var hasAutoUpdateEnabledSubscribe = false
        
        for i in 0..<instance.subscribes.count {
            if instance.subscribes[i].isActive && instance.subscribes[i].getAutoUpdateEnable() {
                hasAutoUpdateEnabledSubscribe = true
                break
            }
        }
        
        let enable = defaults.bool(forKey: USERDEFAULTS_TIME_INTERAVAL_SUBSCRIBE_UPDATE_ENABLE) && hasAutoUpdateEnabledSubscribe
        
        if enable {
            autoUpdateSubscribesTimer?.invalidate()
            autoUpdateSubscribesTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(defaults.integer(forKey: USERDEFAULTS_TIME_INTERAVAL_SUBSCRIBE_UPDATE_TIME) * 3600), repeats: true) { timer in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    instance.updateAllServerFromSubscribe(auto: true, inform: false, ping: true)
                }
            }
        } else {
            autoUpdateSubscribesTimer?.invalidate()
        }
    }
    
    func applyConfig(finish: @escaping(_ success: Bool)->()) {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: USERDEFAULTS_SHADOWSOCKS_ON)
        let mode = defaults.string(forKey: USERDEFAULTS_SHADOWSOCKS_RUNNING_MODE)
        
        if isOn {
            StartSSLocal { (s) in
                if s {
                    StartPrivoxy { (ss) in
                        if ss {
                            if !defaults.bool(forKey: USERDEFAULTS_AUTO_CONFIGURE_NETWORK_SERVICES) {
                                return
                            }
                            
                            if mode == "auto" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enablePACProxy("hi")
                            } else if mode == "global" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enableGlobalProxy()
                            } else if mode == "manual" {
                                ProxyConfHelper.disableProxy("hi")
                            } else if mode == "whiteList" {
                                ProxyConfHelper.disableProxy("hi")
                                ProxyConfHelper.enableWhiteListProxy()//新白名单基于GlobalMode
                            }
                            finish(true)
                        } else {
                            finish(false)
                        }
                    }
                } else {
                    finish(false)
                }
            }
        } else {
            AppDelegate.stopSSR {
                finish(true)
            }
        }
    }
    
    @IBAction func quitApp(_ sender: NSMenuItem) {
        AppDelegate.stopSSR {
            //如果设置了开机启动软件，就不删了
            if self.launchAtLoginController.launchAtLogin == false {
                RemoveSSLocal { (s) in
                    RemovePrivoxy { (ss) in
                        NSApplication.shared.terminate(self)
                    }
                }
            } else {
                NSApplication.shared.terminate(self)
            }
        }
    }
    //------------------------------------------------------------
    // MARK: NSUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func makeToast(_ message: String) {
        if toastWindowCtrl != nil {
            toastWindowCtrl.close()
        }
        
        toastWindowCtrl = ToastWindowController(windowNibName: NSNib.Name("ToastWindowController"))
        toastWindowCtrl.message = message
        toastWindowCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        toastWindowCtrl.window?.makeKeyAndOrderFront(self)
        toastWindowCtrl.fadeInHud()
    }
}
