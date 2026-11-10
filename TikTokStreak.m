//
//  TikTokStreak.m
//  TikTok Auto Streak Pro • iOS Dylib Injection for ESign
//
//  Tweak tự động phát hiện và gửi tin nhắn giữ chuỗi TikTok dành cho iOS.
//  Có thể tiêm trực tiếp vào TikTok.ipa qua tính năng "Tiêm Dylib" của ESign.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - CONFIGURATION & STATE

static BOOL isRunning = NO;
static NSInteger currentStreakIndex = 0;
static NSMutableArray *streakCellsList = nil;
static UIButton *floatingBtn = nil;
static UILabel *hudStatusLabel = nil;
static UIView *hudCard = nil;

#pragma mark - HELPER: RECURSIVE SUBVIEW SEARCH

// Tìm kiếm đệ quy UILabel có chứa icon ngọn lửa 🔥 hoặc từ khóa chuỗi
static BOOL cellContainsStreakIndicator(UIView *view) {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *lbl = (UILabel *)view;
        NSString *txt = lbl.text;
        if (txt && (
            [txt containsString:@"🔥"] ||
            [txt containsString:@"chuỗi"] ||
            [txt containsString:@"Streak"] ||
            [txt containsString:@"streak"] ||
            [txt containsString:@"ngày"]
        )) {
            return YES;
        }
    }
    for (UIView *sub in view.subviews) {
        if (cellContainsStreakIndicator(sub)) {
            return YES;
        }
    }
    return NO;
}

// Tìm ô nhập tin nhắn trong màn hình Chat (UITextView hoặc UITextField)
static UIView *findTextInputView(UIView *view) {
    if ([view isKindOfClass:[UITextView class]] || [view isKindOfClass:[UITextField class]]) {
        return view;
    }
    for (UIView *sub in view.subviews) {
        UIView *found = findTextInputView(sub);
        if (found) return found;
    }
    return NO ? nil : nil;
}

// Tìm nút Gửi (UIButton)
static UIButton *findSendButton(UIView *view) {
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        NSString *title = [btn titleForState:UIControlStateNormal];
        NSString *acc = btn.accessibilityLabel;
        if ((title && ([title containsString:@"Gửi"] || [title containsString:@"Send"])) ||
            (acc && ([acc containsString:@"Gửi"] || [acc containsString:@"Send"] || [acc containsString:@"send"]))) {
            return btn;
        }
    }
    for (UIView *sub in view.subviews) {
        UIButton *found = findSendButton(sub);
        if (found) return found;
    }
    return nil;
}

#pragma mark - AUTO STREAK WORKFLOW ENGINE

static void updateHUD(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (hudStatusLabel) {
            hudStatusLabel.text = msg;
        }
    });
}

static void stopAutoStreak(void) {
    isRunning = NO;
    updateHUD(@"⏹ Đã dừng tiến trình giữ chuỗi.");
}

static void processNextStreakConversation(UINavigationController *navVC, UITableView *tableView);

static void sendStreakMessageAndReturn(UINavigationController *navVC, UITableView *tableView) {
    if (!isRunning) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!isRunning) return;

        UIViewController *chatVC = navVC.topViewController;
        if (!chatVC) {
            stopAutoStreak();
            return;
        }

        // 1. Tìm ô nhập tin nhắn
        UIView *inputView = findTextInputView(chatVC.view);
        if (inputView) {
            if ([inputView isKindOfClass:[UITextView class]]) {
                ((UITextView *)inputView).text = @"🔥";
                [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:inputView];
            } else if ([inputView isKindOfClass:[UITextField class]]) {
                ((UITextField *)inputView).text = @"🔥";
                [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:inputView];
            }
        }

        updateHUD(@"🔥 Đang gửi tin nhắn giữ chuỗi...");

        // 2. Tìm nút gửi hoặc gửi action
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIButton *sendBtn = findSendButton(chatVC.view);
            if (sendBtn) {
                [sendBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
            }

            // 3. Đợi tin gửi thành công và quay lại danh sách Hộp thư
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [navVC popViewControllerAnimated:YES];
                currentStreakIndex++;

                // 4. Tiếp tục người tiếp theo
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    processNextStreakConversation(navVC, tableView);
                });
            });
        });
    });
}

static void processNextStreakConversation(UINavigationController *navVC, UITableView *tableView) {
    if (!isRunning) return;

    if (!streakCellsList || currentStreakIndex >= streakCellsList.count) {
        // Hết danh sách hiện tại -> Cuộn xuống thêm để quét
        updateHUD([NSString stringWithFormat:@"✅ Hoàn thành lượt quét! Tổng: %ld bạn bè.", (long)currentStreakIndex]);
        stopAutoStreak();
        return;
    }

    NSIndexPath *indexPath = streakCellsList[currentStreakIndex];
    updateHUD([NSString stringWithFormat:@"[ %ld / %ld ] Đang mở chat người giữ chuỗi...", (long)(currentStreakIndex + 1), (long)streakCellsList.count]);

    // Cuộn tới ô cần bấm
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!isRunning) return;

        // Mô phỏng sự kiện chọn cell
        if ([tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
        }

        // Bắt đầu chuỗi gửi trong chat
        sendStreakMessageAndReturn(navVC, tableView);
    });
}

static void startAutoStreakScan(void) {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *root = window.rootViewController;

    // Tìm UINavigationController hiện tại
    UINavigationController *nav = nil;
    if ([root isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)root;
    } else if ([root isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected = ((UITabBarController *)root).selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            nav = (UINavigationController *)selected;
        }
    }

    UIViewController *currentVC = nav ? nav.topViewController : root;

    // Tìm UITableView danh sách tin nhắn Hộp thư
    UITableView *targetTableView = nil;
    for (UIView *v in currentVC.view.subviews) {
        if ([v isKindOfClass:[UITableView class]]) {
            targetTableView = (UITableView *)v;
            break;
        }
    }

    if (!targetTableView) {
        updateHUD(@"⚠️ Hãy mở tab 'Hộp thư' (Inbox) trước khi bấm!");
        return;
    }

    isRunning = YES;
    currentStreakIndex = 0;
    streakCellsList = [NSMutableArray array];

    updateHUD(@"🔍 Đang quét danh sách có icon lửa 🔥...");

    NSInteger sections = [targetTableView numberOfSections];
    for (NSInteger s = 0; s < sections; s++) {
        NSInteger rows = [targetTableView numberOfRowsInSection:s];
        for (NSInteger r = 0; r < rows; r++) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:r inSection:s];
            UITableViewCell *cell = [targetTableView cellForRowAtIndexPath:ip];
            if (cell && cellContainsStreakIndicator(cell)) {
                [streakCellsList addObject:ip];
            }
        }
    }

    if (streakCellsList.count == 0) {
        updateHUD(@"❌ Không tìm thấy ai có icon chuỗi 🔥 trên màn hình!");
        stopAutoStreak();
        return;
    }

    updateHUD([NSString stringWithFormat:@"🎯 Tìm thấy %ld người giữ chuỗi. Bắt đầu gửi...", (long)streakCellsList.count]);
    processNextStreakConversation(nav, targetTableView);
}

#pragma mark - FLOATING OVERLAY HUD UI

static void setupFloatingButton(void) {
    if (floatingBtn) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) return;

        // 1. Nút bong bóng nổi 🔥
        floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(win.bounds.size.width - 65, win.bounds.size.height - 200, 52, 52);
        floatingBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.12 alpha:0.92];
        [floatingBtn setTitle:@"🔥" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont systemFontOfSize:26];
        floatingBtn.layer.cornerRadius = 26;
        floatingBtn.layer.borderWidth = 1.5;
        floatingBtn.layer.borderColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.35 alpha:0.9].CGColor;
        floatingBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        floatingBtn.layer.shadowOpacity = 0.4;
        floatingBtn.layer.shadowRadius = 6;
        floatingBtn.layer.shadowOffset = CGSizeMake(0, 3);

        // Kéo thả nút nổi
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:floatingBtn action:@selector(handlePan:)];
        [floatingBtn addGestureRecognizer:pan];

        // 2. Khung điều khiển HUD
        hudCard = [[UIView alloc] initWithFrame:CGRectMake(20, 100, win.bounds.size.width - 40, 160)];
        hudCard.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.1 alpha:0.95];
        hudCard.layer.cornerRadius = 16;
        hudCard.layer.borderWidth = 1;
        hudCard.layer.borderColor = [UIColor colorWithRed:0.2 green:0.25 blue:0.35 alpha:0.8].CGColor;
        hudCard.hidden = YES;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, hudCard.bounds.size.width - 32, 24)];
        title.text = @"💎 TIKTOK AUTO STREAK PRO 💎";
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont boldSystemFontOfSize:14];
        title.textAlignment = NSTextAlignmentCenter;
        [hudCard addSubview:title];

        hudStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 44, hudCard.bounds.size.width - 32, 38)];
        hudStatusLabel.text = @"Sẵn sàng: Vào Hộp thư -> Bấm Bắt đầu";
        hudStatusLabel.textColor = [UIColor colorWithRed:0.0 green:0.95 blue:0.6 alpha:1.0];
        hudStatusLabel.font = [UIFont systemFontOfSize:12];
        hudStatusLabel.numberOfLines = 2;
        hudStatusLabel.textAlignment = NSTextAlignmentCenter;
        [hudCard addSubview:hudStatusLabel];

        // Nút Bắt đầu
        UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        startBtn.frame = CGRectMake(20, 95, (hudCard.bounds.size.width - 60) / 2, 42);
        startBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.45 alpha:1.0];
        [startBtn setTitle:@"▶ Bắt Đầu" forState:UIControlStateNormal];
        [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        startBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        startBtn.layer.cornerRadius = 10;
        [startBtn addTarget:floatingBtn action:@selector(onStartTapped) forControlEvents:UIControlEventTouchUpInside];
        [hudCard addSubview:startBtn];

        // Nút Dừng
        UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        stopBtn.frame = CGRectMake(hudCard.bounds.size.width / 2 + 10, 95, (hudCard.bounds.size.width - 60) / 2, 42);
        stopBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.3 alpha:1.0];
        [stopBtn setTitle:@"⏹ Dừng Lại" forState:UIControlStateNormal];
        [stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        stopBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        stopBtn.layer.cornerRadius = 10;
        [stopBtn addTarget:floatingBtn action:@selector(onStopTapped) forControlEvents:UIControlEventTouchUpInside];
        [hudCard addSubview:stopBtn];

        // Bấm nút nổi để mở/đóng HUD
        [floatingBtn addTarget:floatingBtn action:@selector(toggleHUD) forControlEvents:UIControlEventTouchUpInside];

        [win addSubview:hudCard];
        [win addSubview:floatingBtn];
    });
}

#pragma mark - CATEGORY IMPLEMENTATION FOR BUTTON ACTIONS

@interface UIButton (AutoStreakDrag)
@end

@implementation UIButton (AutoStreakDrag)

- (void)handlePan:(UIPanGestureRecognizer *)p {
    UIView *btn = p.view;
    CGPoint translation = [p translationInView:btn.superview];
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [p setTranslation:CGPointZero inView:btn.superview];
}

- (void)toggleHUD {
    if (hudCard) {
        hudCard.hidden = !hudCard.hidden;
    }
}

- (void)onStartTapped {
    startAutoStreakScan();
}

- (void)onStopTapped {
    stopAutoStreak();
}

@end

#pragma mark - HOOK ENTRYPOINT (AUTOMATIC INJECTION)

__attribute__((constructor))
static void initializeTikTokAutoStreakTweak(void) {
    NSLog(@"[TikTokStreak] 🔥 Tweak Auto Streak Pro đã được nạp thành công vào TikTok!");

    // Lắng nghe khi ứng dụng TikTok hoàn tất khởi chạy
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }];

    // Fallback: Nếu notification đã qua, kích hoạt sau 3 giây
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupFloatingButton();
    });
}
