//
//  ObjcTableViewController.m
//  myProject
//
//  Created by Ryan Chen on 2022/5/31.
//

#import "ObjcTableViewController.h"
#import "myProject-Swift.h"

// The public properties and behavior are defined inside the @interface declaration.
@interface ObjcTableViewController ()

// class extension, 是.h @interface的補充, 但.m的 @interface對外是不開放的, 只在.m裡可見

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *monthOrDaySegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *tableViewShowByMonthLabel;
@property (weak, nonatomic) IBOutlet UIButton *backMonthButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardMonthButton;
@property (weak, nonatomic) IBOutlet UIDatePicker *tableViewDatePicker;

@end

@implementation ObjcTableViewController

// private instance variable

//NSMutableArray *invoiceArray; // = [NSMutableArray arrayWithObject:10];
NSMutableArray *currentFirstMonthInvoice;
NSMutableArray *currentSecondMonthInvoice;
NSMutableArray *currentDayInvoice;

NSString *tableViewHeader = @"2022, 05-06";
NSString *currentFirstMonth;
NSString *currentSecondMonth;
NSString *backMonthButtonTitle = @"\u2190";
NSString *forwardMonthButtonTitle = @"\u2192";




typedef enum _Mode {
    dayMode = 0,
    monthMode
} Mode;

Mode mode = monthMode;

/*
- (return_type) method_name:( argumentType1 )argumentName1
joiningArgument2:( argumentType2 )argumentName2 ...
joiningArgumentn:( argumentTypen )argumentNamen {
   body of the function
}
- functions are instance function
+ functions are class (static) function
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"顯示發票";
    [self.tableView registerNib:[UINib nibWithNibName:@"TotalConsumptionOfMonthTableViewCell" bundle:nil] forCellReuseIdentifier:@"consumptionOfMonthCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MyCustomTableViewCell" bundle:nil] forCellReuseIdentifier:@"customCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.backMonthButton setTitle:backMonthButtonTitle forState:UIControlStateNormal];
    [self.forwardMonthButton setTitle:forwardMonthButtonTitle forState:UIControlStateNormal];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:true];
    NSLog(@"ObjcTableViewController viewWillAppear");
    [self invoiceArrayInit];
    [self monthModeSetting];
    [self.tableView reloadData];
}

- (void)invoiceArrayInit {
    // 要先初始化, 沒初始化沒辦法addObject
    //invoiceArray = [NSMutableArray arrayWithCapacity:0];
    currentFirstMonthInvoice = [NSMutableArray arrayWithCapacity:0];
    currentSecondMonthInvoice = [NSMutableArray arrayWithCapacity:0];
    currentDayInvoice = [NSMutableArray arrayWithCapacity:0];
}

- (void)monthModeSetting {
    mode = monthMode;
    self.monthOrDaySegmentedControl.selectedSegmentIndex = 1;
    self.tableViewShowByMonthLabel.hidden = false;
    self.backMonthButton.hidden = false;
    self.forwardMonthButton.hidden = false;
    self.tableViewDatePicker.hidden = true;
    tableViewHeader = self.tableViewShowByMonthLabel.text;
    
    NSString *year = [tableViewHeader substringToIndex:4];
    currentFirstMonth = [tableViewHeader substringWithRange:NSMakeRange(6, 2)];
    currentSecondMonth = [tableViewHeader substringWithRange:NSMakeRange(9, 2)];
    
    for(Invoice *obj in Invoice.globalInvoiceArray) {
        if([obj.date substringToIndex:4] == year) {
            if([[obj.date substringWithRange:NSMakeRange(5, 2)] isEqualToString: currentFirstMonth]) {
                [currentFirstMonthInvoice addObject:obj];
            } else if([[obj.date substringWithRange:NSMakeRange(5, 2)] isEqualToString:currentSecondMonth]) {
                [currentSecondMonthInvoice addObject:obj];
            }
        }
        //NSLog(@"%@", obj.transformToInfo);
    }
}

- (void)dayModeSetting {
    NSLog(@"dayModeSetting");
    mode = dayMode;
    self.tableViewShowByMonthLabel.hidden = true;
    self.backMonthButton.hidden = true;
    self.forwardMonthButton.hidden = true;
    self.tableViewDatePicker.hidden = false;
    tableViewHeader = [self transformDatePickerToString:self.tableViewDatePicker];

    for(Invoice *obj in Invoice.globalInvoiceArray) {
        if([obj.date.description isEqualToString:tableViewHeader]) {
            [currentDayInvoice addObject:obj];
        }
    }
    
}

- (NSString *)transformDatePickerToString:(UIDatePicker *)datePicker {
    // 把datePicker轉為YYYY-MM-DD格式的String
    NSString *retString = [datePicker.date.description substringToIndex:10];
    return retString;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (mode) {
        case dayMode:
            return @"";
        case monthMode:
            if(section == 0) {
                return [tableViewHeader substringWithRange:NSMakeRange(0, 8)];
            } else {
                return [NSString stringWithFormat:@"%@%@", [tableViewHeader substringWithRange:NSMakeRange(0, 6)], [tableViewHeader substringWithRange:NSMakeRange(9, 2)]];
            }
    }
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 按下發票, 取消cell的選取狀態
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        return;
    }
        
    // 設定選取的發票index, 讓invoiceInfoView呈現出來
    NSInteger invoiceIndex = indexPath.row - 1;
    
    switch (mode) {
    case dayMode:
        Invoice.invoiceShowCurrent = [currentDayInvoice objectAtIndex:invoiceIndex];
        break;
    case monthMode:
        if (indexPath.section == 0) {
            Invoice.invoiceShowCurrent = [currentFirstMonthInvoice objectAtIndex:invoiceIndex];
        } else {
            Invoice.invoiceShowCurrent = [currentSecondMonthInvoice objectAtIndex:invoiceIndex];
        }
        break;
    }
    
    //NSLog([Invoice.invoiceShowCurrent transformToInfo]);
    //self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
    
    InvoiceInfoViewController *vc = [[InvoiceInfoViewController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (mode) {
        case dayMode:
            return 1;
        case monthMode:
            return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (mode) {
        case dayMode:
            return currentDayInvoice.count + 1;
        case monthMode:
            if (section == 0) {
                return currentFirstMonthInvoice.count + 1;
            } else {
                return currentSecondMonthInvoice.count + 1;
            }
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        TotalConsumptionOfMonthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"consumptionOfMonthCell" forIndexPath:indexPath];
        cell.backgroundColor = UIColor.yellowColor;
        int sum = 0;
        switch (mode) {
            case dayMode:
                cell.monthLabel.text = @" 總消費";
                for(Invoice *obj in currentDayInvoice) {
                    sum += [obj.totalPrice integerValue];
                }
                break;
            case monthMode:
                if (indexPath.section == 0) {
                    cell.monthLabel.text = [NSString stringWithFormat:@"%@ 總消費", currentFirstMonth];
                    for(Invoice *obj in currentFirstMonthInvoice) {
                        sum += [obj.totalPrice integerValue];
                    }
                } else {
                    cell.monthLabel.text = [NSString stringWithFormat:@"%@ 總消費", currentSecondMonth];
                    for(Invoice *obj in currentSecondMonthInvoice) {
                        sum += [obj.totalPrice integerValue];
                    }
                }
                break;
        }
        cell.consumptionlabel.text = [NSString stringWithFormat:@"%d", sum];
        return cell;
    } else {
        MyCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customCell" forIndexPath:indexPath];
        NSInteger invoiceIndex = indexPath.row - 1;
        Invoice *invoice;
        switch (mode) {
            case dayMode:
                invoice = [currentDayInvoice objectAtIndex:invoiceIndex];
                break;
            case monthMode:
                if(indexPath.section == 0) {
                    invoice = [currentFirstMonthInvoice objectAtIndex:invoiceIndex];
                } else {
                    invoice = [currentSecondMonthInvoice objectAtIndex:invoiceIndex];
                }
                break;
        }
        
        cell.numberLabel.text = invoice.number;
        cell.storeLabel.text = invoice.storeName;
        cell.dateLabel.text = [invoice.date substringFromIndex:8];
        cell.totalPriceLabel.text = invoice.totalPrice;
        if([cell.storeLabel.text isEqualToString:@""]) {
            cell.storeLabel.text = @"(無店名)";
        }
        
        return cell;
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return nil;
    }
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        NSInteger invoiceIndex = indexPath.row - 1;
        NSString *deleteInvoiceNumber;
        Invoice *deleteInvoice;
        switch (mode) {
            case dayMode:
                deleteInvoice = [currentDayInvoice objectAtIndex:invoiceIndex];
                [currentDayInvoice removeObjectAtIndex:invoiceIndex];
                break;
            case monthMode:
                if(indexPath.section == 0){
                    deleteInvoice = [currentFirstMonthInvoice objectAtIndex:invoiceIndex];
                    [currentFirstMonthInvoice removeObjectAtIndex:invoiceIndex];
                } else {
                    deleteInvoice = [currentSecondMonthInvoice objectAtIndex:invoiceIndex];
                    [currentSecondMonthInvoice removeObjectAtIndex:invoiceIndex];
                }
                break;
        }
        
        deleteInvoiceNumber = deleteInvoice.number;
        
        for(int i=0; i<Invoice.globalInvoiceArray.count; i++) {
            Invoice *invoice = [Invoice.globalInvoiceArray objectAtIndex:i];
            if([invoice.number isEqualToString:deleteInvoiceNumber]) {
                [Invoice removeGlobalInvoiceElement:i];
                break;
            }
        }
        
        // alloc: 分配memory
        MyDatabase *db = [[MyDatabase alloc] init];
        [db removeInvoiceFromDB:deleteInvoiceNumber];
        
        [self.tableView reloadData];
        completionHandler(YES);
    }];
    
    UISwipeActionsConfiguration *swipeActionConfig = [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    //swipeActionConfig.performsFirstActionWithFullSwipe = NO;

    return swipeActionConfig;
}
- (IBAction)dayOrMonthChange:(UISegmentedControl *)sender {
    NSLog(@"dayMonthChange");
    [self invoiceArrayInit];
    switch (mode) {
        case dayMode:
            [self monthModeSetting];
            break;
        case monthMode:
            [self dayModeSetting];
            break;
    }
    
    [self.tableView reloadData];
}
- (IBAction)changeSelectedDate:(UIDatePicker *)sender {
    NSLog(@"選取日期");
    [self invoiceArrayInit];
    [self dayModeSetting];
    [self.tableView reloadData];
}
- (IBAction)selectedMonth:(UIButton *)sender {
    [self invoiceArrayInit];
    
    NSInteger curYear = [[tableViewHeader substringToIndex:4] integerValue];
    NSString *curMonth = [tableViewHeader substringWithRange:NSMakeRange(6, 5)];
    
    
    // NSString *buttonTitle = sender.currentTitle; 會等於nil, 取不到
    NSString *buttonTitle = sender.titleLabel.text;

    // buttonTitle == backMonthButtonTItle not work
    if ([buttonTitle isEqualToString:backMonthButtonTitle]) {
        NSDictionary *backCircularSelectedMonth = @{@"01-02": @"11-12", @"03-04": @"01-02", @"05-06": @"03-04", @"07-08": @"05-06", @"09-10": @"07-08", @"11-12": @"09-10"};
        if ([curMonth isEqual: @"01-02"]) {
            curYear -= 1;
        }
        self.tableViewShowByMonthLabel.text = [NSString stringWithFormat:@"%ld, %@", curYear, backCircularSelectedMonth[curMonth]];
    } else {
        NSDictionary *forwardCircularSelectedMonth = @{@"01-02": @"03-04", @"03-04": @"05-06", @"05-06": @"07-08", @"07-08": @"09-10", @"09-10": @"11-12", @"11-12": @"01-02"};
        if ([curMonth isEqual: @"11-12"]) {
            curYear += 1;
        }
        
        self.tableViewShowByMonthLabel.text = [NSString stringWithFormat:@"%ld, %@", curYear, forwardCircularSelectedMonth[curMonth]];
    }
    
    [self monthModeSetting];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
