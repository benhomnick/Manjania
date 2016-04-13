//
//  ViewController.m
//  Manjana
//
//  Created by superman on 2/2/15.
//  Copyright (c) 2015 superman. All rights reserved.
//

#import "ViewController.h"
#import "UIViewAdditions.h"
#import "StyledPageControl.h"
#import "DataManager.h"
#import "NSDate+Escort.h"

#define kCellHeight 54

@interface ViewController ()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    UIScrollView *indicateScrollView;
    StyledPageControl *pageCtrl;
    UIImageView *logoImageView;
    UIView *view;
    
    UITableView *todoTableView;
    UITextField *btnAdd;
    
    NSMutableArray *todoListArray;
    
    BOOL isHold;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backImageView.image = [UIImage imageNamed:@"bg.jpg"];
    
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = backImageView.bounds;
    [backImageView addSubview:visualEffectView];
    
    [self.view addSubview:backImageView];
    
    logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    logoImageView.center = CGPointMake(self.view.width/2, 100);
    logoImageView.alpha = 0.0;
    [self.view addSubview:logoImageView];

    btnAdd = [[UITextField alloc] initWithFrame:CGRectMake(20, logoImageView.bottom+20, self.view.width-40,kCellHeight)];
    [btnAdd setBackgroundColor:[UIColor whiteColor]];
    [btnAdd setPlaceholder:@"Add new"];
    [btnAdd setTextColor:[UIColor blackColor]];
    [btnAdd setFont:[UIFont fontWithName:@"Georgia-Bold" size:16]];

    UIView *paddingTxtfieldView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, kCellHeight)]; // what ever you want
    btnAdd.leftView = paddingTxtfieldView;
    btnAdd.leftViewMode = UITextFieldViewModeAlways;
    
    btnAdd.hidden = YES;
    btnAdd.alpha = 0.0;
    [self.view addSubview:btnAdd];
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    gesture.minimumPressDuration = 0.4f;
    gesture.allowableMovement = 600;
    [self.view addGestureRecognizer:gesture];

    isHold = NO;
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelCreate)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneCreate)],
                           nil];
    [numberToolbar sizeToFit];
    btnAdd.inputAccessoryView = numberToolbar;
    
    todoTableView = [[UITableView alloc] initWithFrame:CGRectMake(20, btnAdd.bottom+2, self.view.width-40, self.view.height-btnAdd.bottom-20)];
    todoTableView.backgroundColor = [UIColor clearColor];
    todoTableView.delegate = self;
    todoTableView.dataSource = self;
    todoTableView.hidden = YES;
    todoTableView.alpha = 0.0;
    
    [todoTableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [todoTableView setSeparatorColor:[UIColor clearColor]];
    
    [self.view addSubview:todoTableView];
    
    if([[[DataManager SharedDataManager] defaultUserObjectForKey:@"initialLoad"] boolValue]) {
        [self updateTodos];
        [UIView animateWithDuration:0.7 animations:^{
            logoImageView.alpha = 1.0;
            todoTableView.hidden = NO;
            todoTableView.alpha = 1.0;
            todoTableView.hidden = NO;
            btnAdd.hidden = NO;
            btnAdd.alpha = 1.0;
        }];

    } else {
        [self initIndicateView];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTodos) name:@"RemoveExpiredTodos" object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerElapsed) userInfo:nil repeats:YES];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)handleGesture:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        isHold = YES;
        btnAdd.textColor = [UIColor whiteColor];
        btnAdd.backgroundColor = [UIColor blackColor];
        [self getPlannedData];
        [btnAdd setText:[NSString stringWithFormat:@"%d tasks planned for tomorrow",(int)todoListArray.count]];

        [todoTableView reloadData];
        NSLog(@"Hold....");
    }
    else if (gesture.state == UIGestureRecognizerStateCancelled ||
             gesture.state == UIGestureRecognizerStateFailed ||
             gesture.state == UIGestureRecognizerStateEnded)
    {
        isHold = NO;
        btnAdd.textColor = [UIColor blackColor];
        btnAdd.backgroundColor = [UIColor whiteColor];
        [btnAdd setText:@""];
        [self getData];
        [todoTableView reloadData];

        NSLog(@"Hold Off...");
    }

}
- (void)todoAddAction:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Todo"
                                                    message:@"Enter a name for the Todo"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Add", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    [alert show];
}
- (void) initIndicateView {
    
    view = [[UIView alloc] initWithFrame:self.view.bounds];
    
    indicateScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    indicateScrollView.contentSize = CGSizeMake(self.view.width*4, self.view.height);
    indicateScrollView.showsVerticalScrollIndicator = NO;
    indicateScrollView.showsHorizontalScrollIndicator = NO;
    indicateScrollView.pagingEnabled = YES;
    indicateScrollView.delegate = self;
    
    UIImageView *screenView1 = [[UIImageView alloc] initWithFrame:self.view.bounds];
    UIImageView *infoView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Single_Tap.png"]];
    infoView1.center = CGPointMake(screenView1.width/2, screenView1.height/2-50);
    UILabel *lblInfo1 = [[UILabel alloc] initWithFrame:CGRectMake(0, infoView1.bottom+20, view.width, 56)];
    lblInfo1.textColor = [UIColor whiteColor];
    lblInfo1.font = [UIFont fontWithName:@"Georgia-Bold" size:22];
    lblInfo1.text = @"Tap Add new to add\nyour todos";
    lblInfo1.numberOfLines = 2;
    lblInfo1.textAlignment = NSTextAlignmentCenter;
    [screenView1 addSubview:infoView1];
    [screenView1 addSubview:lblInfo1];
    
    UIImageView *screenView2 = [[UIImageView alloc] initWithFrame:self.view.bounds];
    screenView2.left = screenView1.right;
    UIImageView *infoView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Swipe_Left.png"]];
    infoView2.center = CGPointMake(screenView2.width/2, screenView2.height/2-50);
    UILabel *lblInfo2 = [[UILabel alloc] initWithFrame:CGRectMake(0, infoView2.bottom+20, view.width, 56)];
    lblInfo2.textColor = [UIColor whiteColor];
    lblInfo2.font = [UIFont fontWithName:@"Georgia-Bold" size:22];
    lblInfo2.text = @"Swipe your todos left\nand be done";
    lblInfo2.numberOfLines = 2;
    lblInfo2.textAlignment = NSTextAlignmentCenter;
    [screenView2 addSubview:lblInfo2];
    [screenView2 addSubview:infoView2];

    UIImageView *screenView3 = [[UIImageView alloc] initWithFrame:self.view.bounds];
    screenView3.left = screenView2.right;
    UIImageView *infoView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Swipe_Right.png"]];
    infoView3.center = CGPointMake(screenView3.width/2, screenView3.height/2-50);
    UILabel *lblInfo3 = [[UILabel alloc] initWithFrame:CGRectMake(0, infoView3.bottom+20, view.width, 56)];
    lblInfo3.textColor = [UIColor whiteColor];
    lblInfo3.font = [UIFont fontWithName:@"Georgia-Bold" size:22];
    lblInfo3.text = @"Swipe your todos right\nand plan tomorrow";
    lblInfo3.numberOfLines = 2;
    lblInfo3.textAlignment = NSTextAlignmentCenter;
    [screenView3 addSubview:lblInfo3];
    [screenView3 addSubview:infoView3];
    
    [indicateScrollView addSubview:screenView1];
    [indicateScrollView addSubview:screenView2];
    [indicateScrollView addSubview:screenView3];
    
    [view addSubview:indicateScrollView];
    
    pageCtrl = [[StyledPageControl alloc] initWithFrame:CGRectMake(0, lblInfo1.bottom+30, view.width, 30)];
    pageCtrl.numberOfPages = 3;
    pageCtrl.currentPage = 0;
    [pageCtrl setPageControlStyle:PageControlStyleStrokedCircle];
    [pageCtrl setCoreSelectedColor:[UIColor whiteColor]];
    [pageCtrl setStrokeNormalColor:[UIColor whiteColor]];
    [pageCtrl setStrokeSelectedColor:[UIColor whiteColor]];
    [pageCtrl setStrokeWidth:1];
    [pageCtrl setDiameter:16];
    [pageCtrl addTarget:self action:@selector(onPageControlPageChanged:) forControlEvents:UIControlEventValueChanged];

    [view addSubview:pageCtrl];
    
    [self.view addSubview:view];
}
- (void)onPageControlPageChanged:(UIPageControl *)pageControl_ {
    float kScrollObjWidth = self.view.width;
    int offsetX = pageControl_.currentPage * kScrollObjWidth;
    
    CGPoint offset = CGPointMake(offsetX, 0);
    
    [indicateScrollView setContentOffset:offset animated:YES];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView_ {
    
    int page = indicateScrollView.contentOffset.x / indicateScrollView.frame.size.width;
    pageCtrl.currentPage = page;
    if(page>2) {
        [UIView animateWithDuration:0.7 animations:^{
            pageCtrl.alpha = 0.0;
            indicateScrollView.alpha = 0.0;
            logoImageView.alpha = 1.0;
            todoTableView.hidden = NO;
            todoTableView.alpha = 1.0;
            btnAdd.hidden = NO;
            btnAdd.alpha = 1.0;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
            [pageCtrl removeFromSuperview];
            [indicateScrollView removeFromSuperview];
            
            [[DataManager SharedDataManager] setDefaultUserObject:[NSNumber numberWithBool:YES] forKey:@"initialLoad"];
            [[DataManager SharedDataManager] update];
            
            [self getData];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return todoListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UILabel *lblContent = nil;
    UIView *contentView = nil;
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,tableView.width,kCellHeight-2)];
        contentView.backgroundColor = [UIColor whiteColor];
        contentView.tag = 9;
        
        lblContent = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, contentView.width-40, contentView.height)];
        lblContent.textColor = [UIColor blackColor];
        lblContent.font = [UIFont fontWithName:@"Georgia" size:16];
        lblContent.tag = 10;
        
        [cell addSubview:contentView];
        [cell addSubview:lblContent];
        
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell addGestureRecognizer:swipeLeft];
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [cell addGestureRecognizer:swipeRight];

        UIView * additionalSeparator = [[UIView alloc] initWithFrame:CGRectMake(0,kCellHeight-2,tableView.width,2)];
        additionalSeparator.backgroundColor = [UIColor clearColor];
        
        [cell addSubview:additionalSeparator];
    }
    lblContent = (UILabel*)[cell viewWithTag:10];
    contentView = (UIView*)[cell viewWithTag:9];

    if(isHold) {
        lblContent.textColor = [UIColor whiteColor];
        contentView.backgroundColor = [UIColor blackColor];
    } else {
        lblContent.textColor = [UIColor blackColor];
        contentView.backgroundColor = [UIColor whiteColor];
    }
    
    NSManagedObject *objIndex = [todoListArray objectAtIndex:indexPath.row];
    NSLog(@"%@",[objIndex valueForKey:@"order"]);
    lblContent.text = [objIndex valueForKey:@"title"];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}
- (void)tableViewScrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = [todoTableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [todoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}
#pragma mark - 
#pragma mark Core Data Management
- (void) doneCreate {
    NSString *filteredString = [btnAdd.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([filteredString isEqualToString:@""])
        return;
    
    DataManager *dm = [DataManager SharedDataManager];
    NSManagedObject *record = [dm newObjectForEntityForName:@"TodoList"];
    [record setValue:btnAdd.text forKey:@"title"];
    NSDate *createDate = [NSDate date];
    [record setValue:createDate forKey:@"createdAt"];
    [record setValue:createDate forKey:@"deleteAt"];
    [record setValue:[NSNumber numberWithInt:[self getMaxCount]] forKey:@"order"];
    [record didSave];
    [dm update];
    
    [self updateTodos];
    [btnAdd resignFirstResponder];
    btnAdd.text = @"";
    
}
- (void)cancelCreate {
    [btnAdd resignFirstResponder];
    btnAdd.text = @"";
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // The user created a new item, add it
    if (buttonIndex == 1) {
        // Get the input text
        NSString *newItem = [[alertView textFieldAtIndex:0] text];
        NSString *filteredString = [newItem stringByReplacingOccurrencesOfString:@" " withString:@""];
        if([filteredString isEqualToString:@""])
            return;
        DataManager *dm = [DataManager SharedDataManager];
        NSManagedObject *record = [dm newObjectForEntityForName:@"TodoList"];
        [record setValue:newItem forKey:@"title"];
        NSDate *createDate = [NSDate date];
        [record setValue:createDate forKey:@"createdAt"];
        [record setValue:createDate forKey:@"deleteAt"];
        [record setValue:[NSNumber numberWithInt:[self getMaxCount]] forKey:@"order"];
        [record didSave];
        [dm update];
        
        [self updateTodos];
        [self tableViewScrollToBottomAnimated:YES];
    }
}

- (void)getData {
    DataManager *dm = [DataManager SharedDataManager];
    
    NSArray * coreIdeasArray = [dm getResultsWithEntity:@"TodoList" sortDescriptor:@"deleteAt" batchSize:100];
    if(coreIdeasArray.count == 0)
        todoListArray = [NSMutableArray array];
    else
        todoListArray = [NSMutableArray arrayWithArray:coreIdeasArray];
    
    NSArray *tempArray = [todoListArray copy];

    for(NSManagedObject *obj in tempArray) {
        NSDate *date_create = [obj valueForKey:@"createdAt"];
        NSDate *date_delete = [obj valueForKey:@"deleteAt"];
        if(![date_create isEqualToDate:date_delete]) {
            if([date_delete isLaterThanDate:[NSDate date]]) {
                [todoListArray removeObjectIdenticalTo:obj];
            }
        }
    }
}
- (void)getPlannedData {
    DataManager *dm = [DataManager SharedDataManager];
    
    NSArray * coreIdeasArray = [dm getResultsWithEntity:@"TodoList" sortDescriptor:@"deleteAt" batchSize:100];
    if(coreIdeasArray.count == 0)
        todoListArray = [NSMutableArray array];
    else
        todoListArray = [NSMutableArray arrayWithArray:coreIdeasArray];
    
    NSArray *tempArray = [todoListArray copy];
    [todoListArray removeAllObjects];
    for(NSManagedObject *obj in tempArray) {
        NSDate *date_create = [obj valueForKey:@"createdAt"];
        NSDate *date_delete = [obj valueForKey:@"deleteAt"];
        if(![date_create isEqualToDate:date_delete]) {
            if([date_delete isLaterThanDate:[NSDate date]]) {
                [todoListArray addObject:obj];
            }
        }
    }
}
- (int)getMaxCount {
    int count = 0;
    for(NSManagedObject *obj in todoListArray) {
        
        NSDate *date1 = [obj valueForKey:@"createdAt"];
        NSDate *date2 = [obj valueForKey:@"deleteAt"];
        if([date1 compare:date2] == NSOrderedSame) {
            count++;
        } else {
            
        }
    }
    return count;
}
-(int)getLowestOrder {
    int count = 0;
    for(NSManagedObject *obj in todoListArray) {
        
        NSDate *date1 = [obj valueForKey:@"createdAt"];
        NSDate *date2 = [obj valueForKey:@"deleteAt"];
        if([date1 compare:date2] == NSOrderedSame) {

        } else {
            count--;
        }
    }
    return count;

}
- (void)swipeLeft:(UISwipeGestureRecognizer*) swipeGes {
    NSIndexPath *indexPath = [todoTableView indexPathForCell:(UITableViewCell*)[swipeGes view]];
    NSLog(@"Left :%d",(int)indexPath.row);
    NSManagedObject *objTodo = [todoListArray objectAtIndex:indexPath.row];
    int orderNumber = [[objTodo valueForKey:@"order"] intValue];
    if(orderNumber<0) {
        for(int i=0; i<indexPath.row; i++) {
            NSManagedObject *obj = [todoListArray objectAtIndex:i];
            int obj_order = [[obj valueForKey:@"order"] intValue];
            [obj setValue:[NSNumber numberWithInt:obj_order+1] forKey:@"order"];
            [obj didSave];

        }
    } else {
        for(int i=(int)indexPath.row+1; i<todoListArray.count; i++) {
            NSManagedObject *obj = [todoListArray objectAtIndex:i];
            int obj_order = [[obj valueForKey:@"order"] intValue];
            [obj setValue:[NSNumber numberWithInt:obj_order-1] forKey:@"order"];
            orderNumber++;
            [obj didSave];
        }

    }
    [todoListArray removeObjectAtIndex:indexPath.row];
    [[DataManager SharedDataManager].managedObjectContext deleteObject:objTodo];
    [[DataManager SharedDataManager] update];
    [todoTableView deleteRowsAtIndexPaths:@[indexPath]
                     withRowAnimation:UITableViewRowAnimationMiddle];

}
- (void)swipeRight:(UISwipeGestureRecognizer*) swipeGes {
    NSIndexPath *indexPath = [todoTableView indexPathForCell:(UITableViewCell*)[swipeGes view]];
    NSLog(@"Right :%d",(int)indexPath.row);
    NSManagedObject *objTodo = [todoListArray objectAtIndex:indexPath.row];
    int orderNumber = [[objTodo valueForKey:@"order"] intValue];
    NSDate *startTomorrow = [[NSDate date] dateAtEndOfDay];
    [objTodo setValue:startTomorrow forKey:@"deleteAt"];
    [objTodo setValue:[NSNumber numberWithInt:[self getLowestOrder]] forKey:@"order"];
    [objTodo didSave];
    
    for(int i=(int)indexPath.row+1; i<todoListArray.count; i++) {
        NSManagedObject *obj = [todoListArray objectAtIndex:i];
        [obj setValue:[NSNumber numberWithInt:orderNumber] forKey:@"order"];
        orderNumber++;
        [obj didSave];
    }
    
    [[DataManager SharedDataManager] update];
    [todoListArray removeObjectAtIndex:indexPath.row];
    [todoTableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationRight];

}
- (void)updateTodos {
    [self getData];
    [todoTableView reloadData];
}
- (void)timerElapsed {
    if(isHold)
        return;
    BOOL shouldReload = NO;
    for(int i=0; i<todoListArray.count; i++) {
        NSManagedObject *objTodo = [todoListArray objectAtIndex:i];
        NSDate *dateExpired = [objTodo valueForKey:@"deleteAt"];
        if([dateExpired isInPast]) {
            shouldReload = YES;
        }
    }
    if([NSDate date].minute != 0)
        shouldReload = NO;
    if(shouldReload)
        [self updateTodos];

}
@end
