//
//  ViewController.m
//  RunLoopTest
//
//  Created by wuweixin on 2019/6/17.
//  Copyright © 2019 cn.wessonwu. All rights reserved.
//

#import "ViewController.h"
#import "Son.h"

@interface NSObject (Sark)
+ (void)foo;
@end
@implementation NSObject (Sark)
- (void)foo {
    NSLog(@"IMP: - [NSObject (Sark) foo]");
}
@end

@interface Sark : NSObject
@property(nonatomic, copy) NSString *name;
@end

@implementation Sark
- (void)speak {
    NSLog(@"my name's %@", self.name);
}
@end

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self addRunLoopObserverWithTag:@"Default" mode:kCFRunLoopDefaultMode];
//    [self addRunLoopObserverWithTag:@"Common" mode:kCFRunLoopCommonModes];
    
    // runtime
    
    id cls = [Sark class];
    void *obj = &cls;
    [(__bridge id)obj speak];
    
    // [self class] == [super class]
    [[Son alloc] init];
    //
    BOOL res1 = [[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res2 = [[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res3 = [[Sark class] isKindOfClass:[Sark class]];
    BOOL res4 = [[Sark class] isMemberOfClass:[Sark class]];
    
    [NSObject foo];
    [[NSObject new] foo];
    
    
}


- (void)addRunLoopObserverWithTag: (NSString *)tag mode: (CFRunLoopMode) mode {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        /*
         kCFRunLoopEntry = (1UL << 0),          进入工作
         kCFRunLoopBeforeTimers = (1UL << 1),   即将处理Timers事件
         kCFRunLoopBeforeSources = (1UL << 2),  即将处理Source事件
         kCFRunLoopBeforeWaiting = (1UL << 5),  即将休眠
         kCFRunLoopAfterWaiting = (1UL << 6),   被唤醒
         kCFRunLoopExit = (1UL << 7),           退出RunLoop
         kCFRunLoopAllActivities = 0x0FFFFFFFU  监听所有事件
         */
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"%@: 进入", tag);
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"%@: 即将处理Timer事件", tag);
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"%@: 即将处理Source事件", tag);
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"%@: 即将休眠", tag);
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"%@: 被唤醒", tag);
                break;
            case kCFRunLoopExit:
                NSLog(@"%@: 退出RunLoop", tag);
                break;
            default:
                break;
        }
    });
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, mode);
}
- (IBAction)onSetNeedsLayoutClick:(UIButton *)sender {
    [sender setNeedsUpdateConstraints];
}

#pragma MARK - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"IndexPath: %@", indexPath];
    return cell;
}

#pragma MARK - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#if DEBUG
    NSLog(@"点击: %ld", (long)indexPath.row);
#endif
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
