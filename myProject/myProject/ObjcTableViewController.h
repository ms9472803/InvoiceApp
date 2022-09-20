//
//  ObjcTableViewController.h
//  myProject
//
//  Created by Ryan Chen on 2022/5/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjcTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

// 這裡的 @property和functions都能夠被其他class看到

@end

NS_ASSUME_NONNULL_END
