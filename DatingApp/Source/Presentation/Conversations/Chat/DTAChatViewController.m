//
//  DTAChatViewController.m
//  DatingApp
//
//  Created by Maksim on 09.10.15.
//  Copyright © 2015 Cleveroad Inc. All rights reserved.
//

#define TABBAR_HEIGHT 49.0
#define TEXTFIELD_HEIGHT 70.0
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

NSString * const kChatSendMessageId = @"chatId";
NSString * const kChatSendMessageText = @"message";

typedef NS_ENUM(NSUInteger, DTAChatMessageEnum) {
    DTAChatMessageEnumBg = 1,
    DTAChatMessageEnumMessage,
    DTAChatMessageEnumDate
};

#import "DTAChatViewController.h"
#import "UserDetailedInfoViewController.h"
#import "DTAMessage.h"
#import "User+Extension.h"
#import "MBProgressHUD.h"
#import "NSDate+ChatTimeFormat.h"

// SmartEye Nov 25
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <Foundation/Foundation.h>
#import "socket.io.js.v3.h"

static NSString * const myCellIdentifier = @"DTAChatMyCell";
static NSString * const frienfCellIdentifier = @"DTAChatFriendCell";
static NSString * const dateCellIdentifierDate = @"DTAChatDateCell";

@interface DTAChatViewController () <UITextFieldDelegate, WKScriptMessageHandler>

@property(nonatomic, strong) IBOutlet UITextField *tfEntry;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) User *companionUser;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, assign) BOOL firstRun;
@property (nonatomic, assign) BOOL showKyboard;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *height;
@property (nonatomic, assign) CGFloat heightK;
@property (nonatomic, assign) CGFloat addHeght;
@property (nonatomic, assign) BOOL insetrCell;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tbleViewBottomConstraint;

// SmartEye Nov 25
@property (nonatomic, strong) WKWebView *webView;
@property ( nonatomic) UIButton *btnBack;
@property ( nonatomic) UIButton *btnUnMatch;
@property ( nonatomic) UIImageView *imgProfile;
@property ( nonatomic) UILabel *lblName;
@property ( nonatomic) UILabel *lblStatus;
@property ( nonatomic) UILabel *lblMatched;

@end

@implementation DTAChatViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnBack addTarget:self action:@selector(pressBackButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnBack setImage:[UIImage imageNamed:@"btn_back"] forState:UIControlStateNormal];
    self.btnBack.frame = CGRectMake(24.0, 60.0, 48.0, 50.0);
    [self.view addSubview:self.btnBack];
    
    self.btnUnMatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnUnMatch addTarget:self action:@selector(actionPressRightBarButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnUnMatch setImage:[UIImage imageNamed:@"btn_unMatch"] forState:UIControlStateNormal];
    self.btnUnMatch.frame = CGRectMake(self.view.frame.size.width - 72.0, 60.0, 48.0, 50.0);
    [self.view addSubview:self.btnUnMatch];      
    
    self.imgProfile = [[UIImageView alloc] initWithFrame: CGRectMake((self.view.frame.size.width - 68.0)/2, 56.0, 68.0, 68.0)];
    if (self.isFriendDeleted) {
        [self.imgProfile setImage:[UIImage imageNamed:@"deletedUser"]];
    } else if (self.avatarUrl) {
        [self.imgProfile sd_setImageWithURL:self.avatarUrl placeholderImage:[UIImage imageNamed:@"drefaultImage"] options:SDWebImageDelayPlaceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
        }];
    } else {
        [self.imgProfile setImage:[UIImage imageNamed:@"drefaultImage"]];
    }
    [self.imgProfile setContentMode:UIViewContentModeScaleAspectFit];
    self.imgProfile.layer.cornerRadius = 12;
    self.imgProfile.layer.masksToBounds = YES;
    [self.view addSubview:self.imgProfile];
    
    NSArray *words = [self.titleString componentsSeparatedByString: @" "];
    NSString *firstName = [[NSString alloc] initWithString: words[0]];
    firstName = [firstName stringByReplacingOccurrencesOfString:@","
                                         withString:@""];
    
    self.lblName = [[UILabel alloc] initWithFrame:CGRectMake(70, 128, self.view.frame.size.width - 140, 26)];
    [self.lblName setTextAlignment: NSTextAlignmentCenter];
    self.lblName.font = [UIFont systemFontOfSize:25 weight:UIFontWeightSemibold];
    [self.lblName setTextColor:[UIColor blackColor]];
    [self.lblName setNumberOfLines:1];
    self.lblName.text = firstName;
    [self.view addSubview: self.lblName];
    
    self.lblStatus = [[UILabel alloc] initWithFrame:CGRectMake(70, 160, self.view.frame.size.width - 140, 22)];
    [self.lblStatus setTextAlignment:NSTextAlignmentCenter];
    self.lblStatus.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    [self.lblStatus setTextColor:colorGray];
    [self.lblStatus setNumberOfLines:1];
    self.lblStatus.text = @"ACITVE 5M";
    [self.view addSubview: self.lblStatus];
    
    self.lblMatched = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 300)/2, 192, 300, 20)];
    [self.lblMatched setTextAlignment:NSTextAlignmentCenter];
    self.lblMatched.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [self.lblMatched setTextColor:colorGray];
    [self.lblMatched setNumberOfLines:1];
    self.lblMatched.text = [NSString stringWithFormat:@"YOU MATCHED WITH %@ ON %@", firstName, @""];
    [self.view addSubview: self.lblMatched];
    
    UILabel *lineLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(1, 201, (self.view.frame.size.width - 320)/2, 1)];
    [lineLabel1 setBackgroundColor:colorGray];
    [self.view addSubview: lineLabel1];
    
    UILabel *lineLabel2 = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width + 320)/2, 201, (self.view.frame.size.width - 320)/2, 1)];
    [lineLabel2 setBackgroundColor:colorGray];
    [self.view addSubview: lineLabel2];
    
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if (self.isFriendDeleted) {
        self.buttonSend.enabled = NO;
        self.btnUnMatch.enabled = NO;
    } else {
        self.companionUser = [User MR_findFirstByAttribute:@"userId" withValue:self.friendId];
    
        if (!self.companionUser) {
            self.btnUnMatch.enabled = NO;
        }
        
        __weak typeof(self) weakSelf = self;
        
        [DTAAPI profileFullFetchForUserId:self.friendId completion:^(NSError *error, NSArray *dataArr) {
            if (error) {
                NSLog(@"Fail profileFetchForUser request");
            }
            else {
                weakSelf.companionUser = [User MR_findFirstByAttribute:@"userId" withValue:weakSelf.friendId];
                self.detailedUser = [[User alloc] initWithDictionary:dataArr[0]];
                self.btnUnMatch.enabled = YES;
            }
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeLastReadAt) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.dataArr = [NSMutableArray new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 77.0;
    
    self.firstRun = true;
    self.userId = [[User currentUser] userId];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    [self connectToSoket];
}

- (void)dealloc {
    if ((self.chatId != nil) && (self.userId != nil) && (self.friendId != nil)) {
        [self sendEvent:kLSSocketTyping withPayload:@[@{kChatSendMessageId:self.chatId, @"fromUserID": self.userId,@"toUserID": self.friendId,@"status":@false}]];
    }
    
    [self writeLastReadAt];
    [self disconnect];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    textView.enablesReturnKeyAutomatically = YES;
    [self registerForKeyboardNotifications];
    [self writeLastReadAt];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    
    [self freeKeyboardNotifications];
    [self writeLastReadAt];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appDidEnterBackground {
    [self.view endEditing:YES];
    [self writeLastReadAt];
}

- (void)writeLastReadAt{
    if ((self.chatId != nil) && (self.userId != nil) ) {
        [self sendEvent:kLSSocketEventLastReadAt withPayload:@[@{kChatSendMessageId:self.chatId, @"fromUserID": self.userId}]];
    }
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    containerView = [[UIView alloc] init];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height >= 812) {
        containerView.frame = CGRectMake(24, self.view.frame.size.height - 100, self.view.frame.size.width - 48, 64);
        [textView resignFirstResponder];
    }else{
        containerView.frame = CGRectMake(24, self.view.frame.size.height - 80, self.view.frame.size.width - 48, 64);
        [textView resignFirstResponder];
    }
    containerView.layer.borderWidth = 1.0;
    containerView.layer.borderColor = colorBorder.CGColor;
    containerView.layer.cornerRadius = 32;
    containerView.layer.masksToBounds = YES;
    
    textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(10, 7, containerView.frame.size.width - 80, 50)];
    textView.isScrollable = NO;
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    textView.minNumberOfLines = 1;
    textView.maxNumberOfLines = 3;
    // you can also set the maximum height in points with maxHeight
    // textView.maxHeight = 200.0f;
    textView.minHeight = 50.0f;
    textView.font = [UIFont systemFontOfSize:18];
    textView.returnKeyType = UIReturnKeyDefault;
    textView.textColor = [UIColor blackColor];
    textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
//    textView.backgroundColor = [UIColor colorWithRed:255.f/255.f green:255.f/255.f blue:241.f/255.f alpha:1.0];
    textView.placeholder = @"Message...";
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    doneBtn.frame = CGRectMake(containerView.frame.size.width - 60, 10, 45, 45);
    doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [doneBtn setBackgroundImage:[UIImage imageNamed:@"btn_send"] forState: UIControlStateNormal];
    doneBtn.enabled=NO;
    [doneBtn addTarget:self action:@selector(sendBtnAction:) forControlEvents:UIControlEventTouchUpInside];

    [containerView addSubview:textView];
    [containerView addSubview:doneBtn];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    containerView.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:containerView];
            
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 212, self.view.frame.size.width, containerView.frame.origin.y - 212 - 10) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor=[UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView=[UIView new];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth
    |UIViewAutoresizingFlexibleHeight;
    [self.tableView registerNib:[UINib nibWithNibName:@"DTAChatMyCell" bundle:nil] forCellReuseIdentifier:myCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"DTAChatFriendCell" bundle:nil] forCellReuseIdentifier:frienfCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"DTAChatDateCell" bundle:nil] forCellReuseIdentifier:dateCellIdentifierDate];
    
    [self.view addSubview:self.tableView];
}

#pragma mark - IBActions

- (IBAction)pressBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)actionPressRightBarButton:(id)sender {
    [self performSegueWithIdentifier:toDetailedUserInfoSegue sender:self];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
//    if (screenSize.height >= 812)
//        containerView.frame = CGRectMake(0, self.view.frame.size.height - 94, self.view.frame.size.width, 80);
//    else
//        containerView.frame = CGRectMake(0, self.view.frame.size.height - 70, self.view.frame.size.width, 80);
    
    if (screenSize.height >= 812) {
        containerView.frame = CGRectMake(24, self.view.frame.size.height - 100, self.view.frame.size.width - 48, 64);
    }else{
        containerView.frame = CGRectMake(24, self.view.frame.size.height - 80, self.view.frame.size.width - 48, 64);
    }
    
    [textView resignFirstResponder];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if(![self.dataArr[indexPath.row] isKindOfClass:[NSString class]]) {
        DTAMessage *ms = self.dataArr[indexPath.row];
        
        if([self.userId isEqualToString:ms.from]) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"DTAChatMyCell"];
            
            UIView *bg = [cell viewWithTag:DTAChatMessageEnumBg];
            [bg.layer setCornerRadius:14.0];
            bg.backgroundColor = colorCreamCan;
            
            UIView *toprightbg = [cell viewWithTag:4];
            toprightbg.backgroundColor = colorCreamCan;
            
            UILabel* message =(UILabel *) [cell viewWithTag:DTAChatMessageEnumMessage];
            message.text = ms.message;
            
            UILabel *date = (UILabel *)[cell viewWithTag:DTAChatMessageEnumDate];
//            date.text = [self timeStringAgoSinceDate:ms];
            date.text = [NSString stringWithFormat:@"Me, %@", [self timeStringAgoSinceDate:ms]];
            
            if(self.insetrCell) {
                self.addHeght += cell.frame.size.height;
                self.insetrCell = NO;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"DTAChatFriendCell"];
        
            UIView *bg = [cell viewWithTag:DTAChatMessageEnumBg];
            [bg.layer setCornerRadius:14.0];
            
            UIView *toprightbg = [cell viewWithTag:4];
            toprightbg.backgroundColor = bg.backgroundColor;
            
            UILabel* message =(UILabel *) [cell viewWithTag:DTAChatMessageEnumMessage];
            message.text = ms.message;
            
            UILabel *date = (UILabel *)[cell viewWithTag:DTAChatMessageEnumDate];
//            date.text = [self timeStringAgoSinceDate:ms];
            NSArray *words = [self.titleString componentsSeparatedByString: @" "];
            NSString *firstName = [[NSString alloc] initWithString: words[0]];
            firstName = [firstName stringByReplacingOccurrencesOfString:@","
                                                 withString:@""];
            date.text = [NSString stringWithFormat:@"%@, %@", firstName, [self timeStringAgoSinceDate:ms]];
            
            if(self.insetrCell) {
                self.addHeght += cell.frame.size.height;
                self.insetrCell = NO;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
    else {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"DTAChatDateCell"];
    
        UILabel* dateLable = (UILabel *)[cell viewWithTag:1];
        dateLable.text = self.dataArr[indexPath.row];
                
        return cell;
    }
}

#pragma mark -

- (void)badgeUpdate {
    [DTAAPI profileFullFetchForUserId_Mapping:[User currentUser].userId completion:^(NSError *error) {
        if (!error) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = [[User currentUser].messagesBadge integerValue];
        } else {
            NSLog(@"here");
        }
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"needToReloadMenu" object:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    
    if (self.dataArr.count > 0) {
        DTAMessage *message = nil;
        
        if([self.dataArr[0] isKindOfClass:[DTAMessage class]]) {
            message = self.dataArr[0];
        } else {
            message = self.dataArr[1];
        }
        
        if (message.messageId) {
            [self sendEvent:kLSSocketEventHistory withPayload:@[@{@"lastMessageId":message.messageId, @"chatId":self.chatId}]];
            [self writeLastReadAt];

            [refreshControl endRefreshing];
        } else {
            [refreshControl endRefreshing];
        }
    } else {
        [refreshControl endRefreshing];
    }
}

- (void)scrollToBottom {
    if(self.dataArr.count > 1) {
        NSIndexPath *indexP = [NSIndexPath indexPathForRow:(self.dataArr.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexP atScrollPosition:UITableViewScrollPositionBottom animated:!self.firstRun];
    }
}

- (void)convertHistoryToArray:(NSArray *)array {
    for (NSInteger i = 0; i < array.count; i++) {
        NSDictionary *dict = array[i];
        [self.dataArr addObject:[[DTAMessage alloc] initWithDictionary:dict]];
    }
    
    NSArray *words = [self.titleString componentsSeparatedByString: @" "];
    NSString *firstName = [[NSString alloc] initWithString: words[0]];
    firstName = [firstName stringByReplacingOccurrencesOfString:@","
                                         withString:@""];
    if (self.dataArr.count > 0 ) {
        DTAMessage *ms = self.dataArr[0];
        
        self.lblMatched.text = [NSString stringWithFormat:@"YOU MATCHED WITH %@ ON %@", firstName, [self convertMatchedTime: ms.time]];
    }
    
    
    [self.tableView reloadData];
}

- (void)addHistory:(NSArray *)array {
    NSMutableArray *tempArr = [NSMutableArray new];

    for (NSInteger i = 0; i < array.count; i++) {
        NSDictionary *dict = array[i];
        [tempArr addObject:[[DTAMessage alloc] initWithDictionary:dict]];
    }
    
    for (NSInteger i = 0; i < tempArr.count; i++) {
        DTAMessage *ms = tempArr[i];
        [self.dataArr insertObject:ms atIndex:i];
    }
}

- (NSString *)convertMatchedTime:(double )time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/DD/YYYY"];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    return [dateFormatter stringFromDate:date];
}

- (NSString *)convertMessageTime:(double )time {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    return [dateFormatter stringFromDate:date];
}

- (BOOL)compareDate:(DTAMessage *)firstMessage nextMessage:(DTAMessage *)nextMessage {
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:firstMessage.time];
    NSDate *nextDate = [NSDate dateWithTimeIntervalSince1970:nextMessage.time];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitDay fromDate:date];
    NSDateComponents *components2 = [gregorianCalendar components:NSCalendarUnitDay fromDate:nextDate];
    
    if (components1.day - components2.day !=  0) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)timeStringAgoSinceDate:(DTAMessage *)message {
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:message.time];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDate *earliest = [now earlierDate:date];
    NSDate *latest = (earliest == now) ? date : now;
    NSDateComponents *components = [calendar components:(NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitSecond) fromDate:earliest toDate:latest options:NSCalendarMatchStrictly];
    
    if (components.year >= 2) {
        return [NSString stringWithFormat:@"%ld years ago", (long)components.year];
    } else if (components.year >= 1) {
        return @"Last year";
    } else if (components.month >= 2) {
        return [NSString stringWithFormat:@"%ld months ago", (long)components.month];
    } else if (components.month >= 1) {
        return @"Last month";
    } else if (components.weekOfYear >= 2) {
        return [NSString stringWithFormat:@"%ld weeks ago", (long)components.weekOfYear];
    } else if (components.weekOfYear >= 1) {
        return @"Last week";
    } else if (components.day >= 2) {
        return [NSString stringWithFormat:@"%ld days ago", (long)components.day];
    } else if (components.day >= 1) {
        return @"Yesterday";
    } else if (components.hour >= 2) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm a"];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        
        return [dateFormatter stringFromDate:date];
        
//        return [NSString stringWithFormat:@"%ld hours ago", (long)components.hour];
//    } else if (components.hour >= 1) {
//        return @"An hour ago";
//    } else if (components.minute >= 2) {
//        return [NSString stringWithFormat:@"%ld minutes ago", (long)components.minute];
//    } else if (components.minute >= 1) {
//        return @"A minute ago";
//    } else if (components.second >= 3) {
//        return [NSString stringWithFormat:@"%ld seconds ago", (long)components.second];
    } else {
        return @"Just now";
    }
}

-(void)sendBtnAction :(id) sender {
    
    if(textView.text.length > 0) {
        doneBtn.enabled=YES;
        NSString *message = textView.text;
        message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (message.length > 0) {
            textView.text = @"";
            
            [self sendEvent:kLSSocketEventMessage withPayload:@[@{kChatSendMessageId:self.chatId, kChatSendMessageText:message}]];
            [self sendEvent:kLSSocketTyping withPayload:@[@{kChatSendMessageId:self.chatId, @"fromUserID": self.userId,@"toUserID": self.friendId,@"status":@false}]];
            [self writeLastReadAt];
        }
    } else {
        doneBtn.enabled=NO;
    }
}

- (void)getMessage:(DTAMessage *)message {
    BOOL insertDate = NO;

    if(self.dataArr.count > 1 && [self compareDate:self.dataArr.lastObject nextMessage:message]) {
        insertDate = YES;
    }
    
    [self.dataArr addObject:message];
    NSMutableArray *indexReload = [NSMutableArray new];
    NSIndexPath *indehP = [NSIndexPath indexPathForRow:(self.dataArr.count - 1) inSection:0];
    
    if(insertDate) {
//        NSIndexPath *indehPDat = [NSIndexPath indexPathForRow:(self.dataArr.count - 2) inSection:0];
//        [indexReload addObject:indehPDat];
    }
    
    [indexReload addObject:indehP];
//    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexReload withRowAnimation:UITableViewRowAnimationLeft];
//    [self.tableView endUpdates];
    [self scrollToBottom];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:toDetailedUserInfoSegue]) {
        UserDetailedInfoViewController *destVC = segue.destinationViewController;
        destVC.detailedUser = self.detailedUser;
        destVC.hideButtons = DTAButtonsHideStateLike + DTAButtonsHideStateDislike + DTAButtonsHideStateChat;
    }
}

#pragma mark - Keyboard

-(void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)freeKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    // get a rect for the textView frame
    CGRect containerFrame = containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
    
    // animations settings
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    // set views with new info
    containerView.frame = containerFrame;
    self.tableView.frame= CGRectMake(0, 212, self.tableView.frame.size.width, containerFrame.origin.y - 212);
    
    [self scrollToBottom];
    
    // commit animations
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note {
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // get a rect for the textView frame
    CGRect containerFrame = containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height >= 812) {
        containerFrame.origin.y = self.view.frame.size.height - 100;

    }else{
        containerFrame.origin.y = self.view.frame.size.height - 80;
    }
    
    // animations settings
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    // set views with new info
    containerView.frame = containerFrame;
    self.tableView.frame= CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, containerFrame.origin.y - 222);
    
    // commit animations
    [UIView commitAnimations];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect r = containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
    containerView.frame = r;
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, containerView.frame.origin.y);
    [self scrollToBottom];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView {
    
    NSLog(@"%@",growingTextView.text);
    
    //    NSString *newString = [growingTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    //
    //    if ([newString rangeOfString:@"\n"].location != NSNotFound) {
    //        newString =[growingTextView.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //    }
    //
    //    if([newString isEqualToString:@""] || [newString isEqualToString:@" "]) {
    //        doneBtn.enabled=NO;
    //    } else {
    //        doneBtn.enabled=YES;
    //    }
    
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    NSLog(@"%lu",(unsigned long)growingTextView.text.length);
    
    if (growingTextView.text.length == 0) {
        if ([text isEqualToString:@" "] || [text isEqualToString:@""] || [text isEqualToString:@"\n"]) {
            doneBtn.enabled=NO;
            textView.text=@"";
            
            return NO;
        }
        doneBtn.enabled=YES;
        return YES;
    } else {
        NSLog(@"%@", self.friendId);
        [self sendEvent:kLSSocketTyping withPayload:@[@{kChatSendMessageId:self.chatId, @"fromUserID": self.userId,@"toUserID": self.friendId,@"status":@true}]];
        doneBtn.enabled=YES;
        return YES;
    }
    return YES;
}

#pragma mark - Socket

- (void) connectToSoket {

        NSString *socketConstructor = socket_io_js_constructor(APP_DELEGATE.accessToken,
                                                               YES,
                                                               -1,
                                                               1,
                                                               5,
                                                               20
        );
    NSLog(@"socketConstructor = %@", socketConstructor);
    
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
                                        'reconnectionDelay': 500,           \
                                        'reconnectionDelayMax': 5000,       \
                                        'timeout': 20000                    \
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
                                  var objc_chatLastReadAt = function(val){                                           \
                                      var messageToPost = {'socketState': 'objc_chatLastReadAt', 'arg': val};        \
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
                                  objc_socket.on('chatLastReadAt', objc_chatLastReadAt);                 \
                                                                                                         \
                                  objc_socket.emit('chatOpen', {\"user\":\"%@\"});                       \
                              };                                                                         \
                                         \
                                         \
                              function onSocketRequest(param) {                 \
                                    var paramArray = param.split(\", \");       \
                                    var arg = JSON.parse(paramArray[1]);        \
                                    var messageToPost = {'socketState': 'objc_status', 'arg': objc_socket.connected};       \
                                    window.webkit.messageHandlers.msgHandler.postMessage(messageToPost);                    \
                                    try {                                       \
                                        objc_socket.emit(paramArray[0], arg);   \
                                    } catch(e) {                                \
                                        console.log(\"socket error: \" + e);    \
                                    }                                           \
                              };                                                \
                              </script></body></html>", socket_io_js, blob_factory_js, APP_DELEGATE.accessToken, self.friendId];

        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *controller = [[WKUserContentController alloc] init];
        [controller addScriptMessageHandler:self name:@"msgHandler"];
        configuration.userContentController = controller;

        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 1, 1) configuration:configuration];
        [self.view addSubview:self.webView];
        [self.webView loadHTMLString:scriptSource baseURL:nil];
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
      
//    __weak typeof(self) weakSelf = self;
    NSLog(@"Received Message from WebView %@", message.body);
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
    } else if( [status isEqualToString:@"objc_connected"] || [status isEqualToString:@"objc_chatHistory"] || [status isEqualToString:@"objc_chatMessage"] || [status isEqualToString:@"objc_chatOpen"] || [status isEqualToString:@"objc_typing"] || [status isEqualToString:@"objc_chatClearHistory"] || [status isEqualToString:@"objc_profileRemoved"] || [status isEqualToString:@"objc_profileBlocked"] || [status isEqualToString:@"objc_chatRemoved"] || [status isEqualToString:@"objc_chatLastReadAt"] ) {
        
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
       
    } else if([status isEqualToString:@"objc_status"]){
        if ([dict[@"arg"] boolValue]){
            NSLog(@" Keep Socket");
        } else {
            NSLog(@" Disconnect Socket");
        }
    } else {
        NSLog(@"Socket couldn't be created");
    }
}

#pragma mark - Listener Delegate

- (void)sendListenEvent:(NSString *)event withPayload:(NSArray *)payload
{
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    
    NSString *tmpEvent = [event stringByReplacingOccurrencesOfString:@"objc_" withString:@""];
    NSString *titleString = [NSString stringWithFormat:@"%@\n%@", self.titleString, @"typing"];
    UILabel *lTitle = (UILabel *)self.navigationItem.titleView;
    
    if ([tmpEvent isEqualToString:kLSSocketTyping]) {

        if ([[[payload objectAtIndex:0] valueForKey:@"status"] boolValue] == true) {//
                lTitle.text = titleString;
                lTitle.numberOfLines = 2;
        }
        else {
            lTitle.text = self.titleString;
        }
    }
    
    if ([tmpEvent isEqualToString:kLSSocketEventOpen]) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        if (self.firstRun) {
            [self convertHistoryToArray:payload[0][@"messages"]];
            self.addHeght = self.heightK;
            if (!self.chatId) {
                self.chatId = payload[0][@"id"];
            }
            self.firstRun = NO;
            if (self.dataArr.count > 4) {
                NSIndexPath *indexP = [NSIndexPath indexPathForRow:(self.dataArr.count - 1) inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexP atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
        }
        
        [self writeLastReadAt];
        
    } else if ([tmpEvent isEqualToString:kLSSocketEventMessage]) {
        if ([self.chatId isEqualToString:payload[0][@"chatId"]]) {
            self.insetrCell = YES;
            [self getMessage:[[DTAMessage alloc] initWithDictionary:payload[0][@"message"]]];
        }
    } else if ([tmpEvent isEqualToString:kLSSocketEventConnect]) {

    } else if ([tmpEvent isEqualToString:kLSSocketEventHistory]) {
        [self addHistory:payload[0][@"messages"]];
    } else if ([tmpEvent isEqualToString:kLSSocketEventLastReadAt]) {
        [self badgeUpdate];
    }
}

@end
