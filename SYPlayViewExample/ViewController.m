//
//  ViewController.m
//  SYPlayViewExample
//
//  Created by shenyuanluo on 2018/6/18.
//  Copyright © 2018年 http://blog.shenyuanluo.com/ All rights reserved.
//

#import "ViewController.h"
#import "I420ViewController.h"
#import "RGB24ViewController.h"

@interface ViewController() <
                                UITableViewDataSource,
                                UITableViewDelegate
                            >

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"SYPlayView";
    self.tableView.rowHeight = 44.0f;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"-------- ViewController dealloc --------");
}


- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - TableView Datasource and Delegate
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"SYPlayViewExampleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellId];
    }
    NSUInteger rowIndex = indexPath.row;
    if (0 == rowIndex)
    {
        cell.textLabel.text = @"I420";
    }
    else if (1 == rowIndex)
    {
        cell.textLabel.text = @"RGB24";
    }
    else
    {
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSUInteger rowIndex = indexPath.row;
    if (0 == rowIndex)
    {
        I420ViewController *i420VC = [[I420ViewController alloc] init];
        [self.navigationController pushViewController:i420VC
                                             animated:YES];
    }
    else if (1 == rowIndex)
    {
        RGB24ViewController *rgb24VC = [[RGB24ViewController alloc] init];
        [self.navigationController pushViewController:rgb24VC
                                             animated:YES];
    }
    else
    {
        
    }
}

@end
