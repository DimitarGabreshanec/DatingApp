//
//  DTAConversationsViewController.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import "DTAConversationsViewController.h"
#import "DTAChatViewController.h"
#import "DTAconversation.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DTAConversationsTableViewCell.h"
#import "User+Extension.h"

// SmartEye Nov 25
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "socket.io.js.v3.h"

@interface DTAConversationsViewController () <UITableViewDelegate, UITableViewDataSource, WKScriptMessageHandler>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) NSMutableArray *hiddenConversationArr;
@property (nonatomic, strong) NSIndexPath *deletrRow;

// SmartEye Nov 25
@property (nonatomic, strong) WKWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *messsgesLabel;
@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;

@end

@implementation DTAConversationsViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    self.navigationController.navigationBar.barTintColor = colorCreamCan;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName :[UIColor whiteColor]};

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogOut) name:@"userLogOut" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeUpdate) name:UIApplicationWillEnterForegroundNotification object:nil];

    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.hiddenConversationArr = [NSMutableArray new];
    self.dataArr = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    APP_DELEGATE.hud = [[SAMHUDView alloc] initWithTitle:nil];
    [APP_DELEGATE.hud show];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeUpdate) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self connectToSoket];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (APP_DELEGATE.firstRun) {
        UINavigationController *loginVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DTARegisterNavigationControllerID"];
        loginVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:loginVC animated:YES completion:nil];
        APP_DELEGATE.firstRun = NO;
    }
    
    [self badgeUpdate];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badgeUpdate) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self disconnect];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self disconnect];
}

- (void)userLogOut {
    [self disconnect];

    [self.dataArr removeAllObjects];
    [self.tableView reloadData];
}

- (void)badgeUpdate {
    [DTAAPI profileFullFetchForUserId_Mapping:[User currentUser].userId completion:^(NSError *error) {
        if (!error) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = [[User currentUser].messagesBadge integerValue];
            self.messsgesLabel.text = [NSString stringWithFormat:@"%li messages", (long)[[User currentUser].messagesBadge integerValue]];
        } else {
            NSLog(@"here");
        }
    }];
}

#pragma mark - TableViewDelegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"data arr count %lu", (unsigned long)self.dataArr.count);
    return self.dataArr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 80 * SCREEN_WIDTH / 375.0;
    return 99;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DTAConversationsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"DTAChatCell" forIndexPath:indexPath];
    DTAconversation *conversation = self.dataArr[indexPath.row];
    NSLog(@"conversation data = %@", conversation);
    [cell configureWithUser:conversation];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Do you want delete conversation?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            DTAconversation *convers = self.dataArr[indexPath.row];
            self.deletrRow = indexPath;
            [self sendEvent:kLSSocketEventClearHistory withPayload:@[@{@"chatId":convers.chatId}]];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        
        [self.navigationController presentViewController:alertController animated:yesAction completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showChat" sender:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)removeConversation {
    DTAconversation *convers = self.dataArr[self.deletrRow.row];
    convers.lastTextMessage = @"";
    [self.hiddenConversationArr addObject:convers];
    [self.dataArr removeObject:convers];
    [self.tableView reloadData];
}

#pragma mark - Internal Methods

- (void)insertNewChatRomDictionary:(NSDictionary *)dictionary {
    
    NSString *idChat = dictionary[@"id"];
    BOOL sameId = NO;
    
    for (DTAconversation *conversation in self.dataArr) {
        if([idChat isEqualToString:conversation.chatId]) {
            sameId = YES;
        }
    }
    
    if(!sameId) {
        DTAconversation *conversation = [[DTAconversation alloc] initWithDictionary:dictionary];
        if(conversation.date == 0) {
            conversation.date = [[NSDate date] timeIntervalSince1970];
        }
        
        if(conversation.lastTextMessage.length > 0) {
            [self.dataArr insertObject:[[DTAconversation alloc] initWithDictionary:dictionary] atIndex:0];
            [self.tableView reloadData];
        } else {
            conversation.date = 0;
            conversation.date = [[NSDate date] timeIntervalSince1970];
            [self.hiddenConversationArr addObject:conversation];
        }
    }
}

- (void)updateConversationTable:(NSDictionary *)dict {
    
    BOOL stop = NO;

    for (DTAconversation *convers in self.dataArr) {
        if([convers.chatId isEqualToString:dict[@"chatId"]]) {
            
            DTAconversation *topConwers = convers;
            topConwers.lastTextMessage = dict[@"message"][@"message"];
            topConwers.date = 0;
            topConwers.date = [[NSDate date] timeIntervalSince1970];
            topConwers.unreadMessages = topConwers.unreadMessages + 1;
            [self.dataArr removeObject:convers];
            [self.dataArr insertObject:topConwers atIndex:0];
            [self.tableView reloadData];
            stop = YES;
            break;
        }
    }
    
    if(!stop) {
        for (DTAconversation *convers in self.hiddenConversationArr) {
            if([convers.chatId isEqualToString:dict[@"chatId"]]) {
                DTAconversation *topConwers = convers;
                topConwers.lastTextMessage = dict[@"message"][@"message"];
                topConwers.date = 0;
                topConwers.date = [[NSDate date] timeIntervalSince1970];
                [self.dataArr insertObject:topConwers atIndex:0];
                [self.tableView reloadData];
                stop = YES;
                break;
            }
        }
    }
}

- (void)handleRemovedCompanionWithPayload:(NSDictionary *)dictionary {
    
    NSString *friendId = dictionary[@"userId"];
    for (DTAconversation *conversation in self.dataArr) {
        if ([conversation.idFriend isEqualToString:friendId]) {
            conversation.isFriendDeleted = YES;
            [self.tableView reloadData];
            break;
        }
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"showChat"]) {
        DTAChatViewController *destVC = segue.destinationViewController;
        destVC.hidesBottomBarWhenPushed = YES;
        NSIndexPath *ip = [self.tableView indexPathForSelectedRow];
        DTAconversation *conversation = self.dataArr[ip.row];
        destVC.titleString = conversation.nameAge;
        destVC.chatId = conversation.chatId;
        destVC.userId = conversation.idUser;
        destVC.avatarUrl = conversation.avatarUrl;
        destVC.friendId = conversation.idFriend;
        destVC.isFriendDeleted = conversation.isFriendDeleted;
    }
}

#pragma mark - Socket
- (void)connectToSoket{

        NSString *socketConstructor = socket_io_js_constructor(APP_DELEGATE.accessToken,
                                                               YES,
                                                               -1,
                                                               1,
                                                               5,
                                                               20
        );
        
        //window onload
        NSString *scriptSource = [NSString stringWithFormat:@"<html><head></head><body><script>  \
                                  %@                                 \
                                  %@                                 \
                                  var objc_socket = null;            \
                                  function connectToSocket() {                  \
                                        if(objc_socket != null) {               \
                                            objc_socket.close();                \
                                        }                                       \
                                        objc_socket = io('%@', {                \
                                            'reconnection': true,               \
                                            'reconnectionAttempts': Infinity,   \
                                            'reconnectionDelay': 1000,          \
                                            'reconnectionDelayMax': 5000,       \
                                            'timeout': 60000,                   \
                                            'forceNew': false                   \
                                        });                                     \
                                  }                                             \
                                  window.onload = function() {                                                 \
                                      connectToSocket();                                                       \
                                             \
                                      if(objc_socket == null){                                                 \
                                         var messageToPost = {'socketState': 'noCreated'};                     \
                                         window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);  \
                                         return;                                                               \
                                      }                                                                        \
                                             \
                                      var objc_onConnect = function(){                                            \
                                          var messageToPost = {'socketState': 'objc_onConnect'};                  \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);    \
                                      };                                                                          \
                                             \
                                      var objc_onDisconnect = function(){                                         \
                                          console.log(\"socket disconnected.\");                                  \
                                          var messageToPost = {'socketState': 'objc_onDisconnect'};               \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);    \
                                      };                                                                          \
                                              \
                                      var objc_onError = function(err){                                           \
                                          var messageToPost = {'socketState': 'objc_onError', 'arg': err};        \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);    \
                                      };                                                                          \
                                              \
                                      var objc_onReconnect = function(val){                                       \
                                          var messageToPost = {'socketState': 'objc_onReconnect', 'arg': val};    \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);    \
                                      };                                                                          \
                                              \
                                      var objc_onReconnectionAttempt = function(val){                                    \
                                          var messageToPost = {'socketState': 'objc_onReconnectionAttempt', 'arg': val}; \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_onReconnectionError = function(err){                                      \
                                          var messageToPost = {'socketState': 'objc_onReconnectionError', 'arg': err};   \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_connected = function(val){                                                \
                                          var messageToPost = {'socketState': 'objc_connected', 'arg': val};             \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_chatHistory = function(val){                                              \
                                          var messageToPost = {'socketState': 'objc_chatHistory', 'arg': val};           \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_chatMessage = function(val){                                              \
                                          var messageToPost = {'socketState': 'objc_chatMessage', 'arg': val};           \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_chatOpen = function(val){                                                 \
                                          var messageToPost = {'socketState': 'objc_chatOpen', 'arg': val};              \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_typing = function(val){                                                   \
                                          var messageToPost = {'socketState': 'objc_typing', 'arg': val};                \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_chatClearHistory = function(val){                                         \
                                          var messageToPost = {'socketState': 'objc_chatClearHistory', 'arg': val};      \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_profileRemoved = function(val){                                           \
                                          var messageToPost = {'socketState': 'objc_profileRemoved', 'arg': val};        \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_profileBlocked = function(val){                                           \
                                          var messageToPost = {'socketState': 'objc_profileBlocked', 'arg': val};        \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      var objc_chatRemoved = function(val){                                              \
                                          var messageToPost = {'socketState': 'objc_chatRemoved', 'arg': val};           \
                                          window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);           \
                                      };                                                                                 \
                                              \
                                      objc_socket.on('connect', objc_onConnect);                             \
                                      objc_socket.on('error', objc_onError);                                 \
                                      objc_socket.on('disconnect', objc_onDisconnect);                       \
                                      objc_socket.on('reconnect', objc_onReconnect);                         \
                                      objc_socket.on('reconnecting', objc_onReconnectionAttempt);            \
                                      objc_socket.on('reconnect_error', objc_onReconnectionError);           \
                                              \
                                      objc_socket.on('connected', objc_connected);                           \
                                      objc_socket.on('chatHistory', objc_chatHistory);                       \
                                      objc_socket.on('chatMessage', objc_chatMessage);                       \
                                      objc_socket.on('chatOpen', objc_chatOpen);                             \
                                      objc_socket.on('typing', objc_typing);                                 \
                                      objc_socket.on('chatClearHistory', objc_chatClearHistory);             \
                                      objc_socket.on('profileRemoved', objc_profileRemoved);                 \
                                      objc_socket.on('profileBlocked', objc_profileBlocked);                 \
                                      objc_socket.on('chatRemoved', objc_chatRemoved);                       \
                                  };                                                                         \
                                              \
                                  function onSocketConnect() {                      \
                                        console.log(objc_socket);                   \
                                        console.log(objc_socket.connected);         \
                                  };                                                \
                                             \
                                  function onSocketRequest(param) {                 \
                                        var paramArray = param.split(\", \");       \
                                        var arg = JSON.parse(paramArray[1]);        \
                                        console.log(objc_socket);                   \
                                        console.log(objc_socket.connected);         \
                                        try {                                       \
                                            objc_socket.emit(paramArray[0], arg);   \
                                        } catch(e) {                                \
                                            console.log(\"socket error: \" + e);    \
                                        }                                           \
                                        console.log(\"socket request sent \" + paramArray[0] );       \
                                  };                                                \
                                  </script></body></html>", socket_io_js, blob_factory_js, APP_DELEGATE.accessToken];
        
        NSLog(@"socketConstructor = %@", socketConstructor);

        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *controller = [[WKUserContentController alloc] init];
        [controller addScriptMessageHandler:self name:@"msgHandler"];
        configuration.userContentController = controller;

        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) configuration:configuration];
        [self.view addSubview:self.webView];
        [self.webView loadHTMLString:scriptSource baseURL:nil];
}

- (void) establishConnect {
    NSLog(@"%@", @"onSocketConnect();");
    NSString *scriptCode = [NSString stringWithFormat: @"onSocketConnect();"];
    [self.webView evaluateJavaScript:scriptCode completionHandler:^(id data, NSError* error) {
        NSLog(@"Error = %@", error.localizedDescription);
    }];
}

- (void)sendEvent:(NSString *)event withPayload:(NSArray *)payload {
    NSLog(@"VC %@ sent event \'%@\' with payload: %@", self, event, payload);
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObject: [NSString stringWithFormat: @"%@", event]];
    for (id arg in payload) {
        if ([arg isKindOfClass: [NSNull class]]) {
            [arguments addObject: @"null"];
        } else if ([arg isKindOfClass: [NSString class]]) {
            [arguments addObject: [NSString stringWithFormat: @"'%@'", arg]];
        } else if ([arg isKindOfClass: [NSNumber class]]) {
            [arguments addObject: [NSString stringWithFormat: @"%@", arg]];
        } else if ([arg isKindOfClass: [NSData class]]) {
            NSString *dataString = [[NSString alloc] initWithData: arg encoding: NSUTF8StringEncoding];
            [arguments addObject: [NSString stringWithFormat: @"blob('%@')", dataString]];
        } else if ([arg isKindOfClass: [NSArray class]] || [arg isKindOfClass: [NSDictionary class]]) {
            [arguments addObject: [[NSString alloc] initWithData: [NSJSONSerialization dataWithJSONObject: arg options: 0 error: nil] encoding: NSUTF8StringEncoding]];
        }
    }

    NSLog(@"%@", [NSString stringWithFormat: @"objc_socket.emit(%@);", [arguments componentsJoinedByString: @", "]]);
    NSString *scriptCode = [NSString stringWithFormat: @"onSocketRequest('%@');", [arguments componentsJoinedByString: @", "]];
    NSLog(@"%@", scriptCode);
    [self.webView evaluateJavaScript:scriptCode completionHandler:^(id data, NSError* error) {
        NSLog(@"Error = %@", error.localizedDescription);
    }];
}

- (void)disconnect{
    [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @"about:blank"]]];
    [self.webView reload];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"msgHandler"];
    [self.webView removeFromSuperview];
    self.webView= nil;
}

#pragma mark -WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController  didReceiveScriptMessage:(WKScriptMessage *)message {

    NSLog(@"Received event %@", message.body);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:message.body];
    NSString *status = [[NSString alloc] initWithString:dict[@"socketState"]];
    NSLog(@"SocketState = %@", status);

    if ([status isEqualToString:@"objc_onConnect"]){
        
        
    } else if ([status isEqualToString:@"objc_onError"]) {
        
        NSMutableDictionary *err = [[NSMutableDictionary alloc] init];
         if ([dict[@"arg"] isKindOfClass: [NSString class]]) {
             [err setValue:dict[@"arg"] forKey:@"error"];
        } else if ([dict[@"arg"] isKindOfClass: [NSDictionary class]]) {
            err = [[NSMutableDictionary alloc] initWithDictionary:dict[@"arg"]];
        }
    } else if ([status isEqualToString:@"objc_onDisconnect"]) {

    } else if ([status isEqualToString:@"objc_onReconnect"]) {
        
        NSInteger value = [[dict objectForKey:@"arg"] integerValue];
        NSLog(@"%zd", value);
    } else if ([status isEqualToString:@"objc_onReconnectionAttempt"]) {
        
        NSInteger value = [[dict objectForKey:@"arg"] integerValue];
        NSLog(@"%zd", value);
    } else if ([status isEqualToString:@"objc_onReconnectionError"]) {
        
        NSMutableDictionary *err = [[NSMutableDictionary alloc] init];
         if ([dict[@"arg"] isKindOfClass: [NSString class]]) {
             [err setValue:dict[@"arg"] forKey:@"error"];
        } else if ([dict[@"arg"] isKindOfClass: [NSDictionary class]]) {
            err = [[NSMutableDictionary alloc] initWithDictionary:dict[@"arg"]];
        }
    } else if( [status isEqualToString:@"objc_connected"] || [status isEqualToString:@"objc_chatHistory"] || [status isEqualToString:@"objc_chatMessage"] || [status isEqualToString:@"objc_chatOpen"] || [status isEqualToString:@"objc_typing"] || [status isEqualToString:@"objc_chatClearHistory"] || [status isEqualToString:@"objc_profileRemoved"] || [status isEqualToString:@"objc_profileBlocked"] || [status isEqualToString:@"objc_chatRemoved"]) {
        
        NSMutableArray *arguments = [NSMutableArray array];
        if ([dict[@"arg"] isKindOfClass: [NSNull class]]) {
            [arguments addObject: @"null"];
        } else if ([dict[@"arg"] isKindOfClass: [NSString class]]) {
            [arguments addObject: [NSString stringWithFormat: @"'%@'", dict[@"arg"]]];
        } else if ([dict[@"arg"] isKindOfClass: [NSNumber class]]) {
            [arguments addObject: [NSString stringWithFormat: @"%@", dict[@"arg"]]];
        } else if ([dict[@"arg"] isKindOfClass: [NSData class]]) {
            NSString *dataString = [[NSString alloc] initWithData: dict[@"arg"] encoding: NSUTF8StringEncoding];
            [arguments addObject: [NSString stringWithFormat: @"blob('%@')", dataString]];
        } else if ([dict[@"arg"] isKindOfClass: [NSArray class]]) {
            [arguments addObjectsFromArray: dict[@"arg"]];
        } else if ([dict[@"arg"] isKindOfClass: [NSDictionary class]]) {
            [arguments addObject: dict[@"arg"]];
        }
        
        [self sendListenEvent: status withPayload: arguments];
        
        
    } else {
        NSLog(@"Socket couldn't be created");
    }
}

#pragma mark - Listener Delegate

- (void)socketDidDisconnect {
    [self.dataArr removeAllObjects];
    [self.tableView reloadData];
}

- (void)sendListenEvent:(NSString *)event withPayload:(NSArray *)payload {
    
    NSString *tmpEvent = [event stringByReplacingOccurrencesOfString:@"objc_" withString:@""];
    
    if ([tmpEvent isEqualToString:kLSSocketEventConnect]) {
        NSMutableArray *tempDataArray = [NSMutableArray new];
        NSMutableArray *tempHiddenConversArray = [NSMutableArray new];
        
        for (NSDictionary *dict in [payload[0] objectForKey:@"chats"]) {
            DTAconversation *conversation = [[DTAconversation alloc] initWithDictionary:dict];
            if (conversation.lastTextMessage.length > 0) {
                if (conversation.blocked == YES) {
                    [tempHiddenConversArray addObject:conversation];
                } else {
                    if (conversation.is_matched == YES) {
                        [tempDataArray addObject:conversation];
                    } else {
                        [tempHiddenConversArray addObject:conversation];
                    }
                }
            } else {
                [tempHiddenConversArray addObject:conversation];
            }
        }
        
//        NSMutableSet *tempValues = [[NSMutableSet alloc] init];
//        NSMutableArray *filterDataArray = [NSMutableArray new];
//        for( DTAconversation *conv in tempDataArray){
//            if(! [tempValues containsObject:conv.chatId]) {
//                [tempValues addObject:conv.chatId];
//                [filterDataArray addObject:conv];
//            }
//        }
        
        NSArray *sortedArray;
        sortedArray = [tempDataArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            double first = [(DTAconversation* )a date];
            double second = [(DTAconversation* )b date];
            if (first > second) {
                return NO;
            } else {
                return YES;
            }
        }];
        
        self.dataArr = nil;
        self.dataArr = [[NSMutableArray alloc] initWithArray:sortedArray];
        self.hiddenConversationArr = nil;
        self.hiddenConversationArr = tempHiddenConversArray;
        [self.tableView reloadData];
        [APP_DELEGATE.hud dismiss];
        
        
    } else if([tmpEvent isEqualToString:kLSSocketEventMessage]) {
        [self updateConversationTable:payload[0]];
    } else if([tmpEvent isEqualToString:kLSSocketEventOpen]) {
        [self insertNewChatRomDictionary:payload[0]];
    } else if ([tmpEvent isEqualToString:kLSSocketEventClearHistory]) {
        [self removeConversation];
    } else if ([tmpEvent isEqualToString:kLSSocketEventProfileRemoved] || [event isEqualToString:kLSSocketEventProfileBlocked] || [event isEqualToString:kLSSocketEventRemoveChatBlocked]) {
        [self handleRemovedCompanionWithPayload:payload[0]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"needToReloadMenu" object:nil];
}

@end
