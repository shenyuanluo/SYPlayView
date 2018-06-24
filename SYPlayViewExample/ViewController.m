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
#import "NV12ViewController.h"
#import "NV21ViewController.h"


#define CELL_HEIGHT 44


@interface ViewController() <
                                UITableViewDataSource,
                                UITableViewDelegate
                            >
{
    NSMutableArray<NSArray *>  *m_dataSource;   // 显示数据
    NSMutableArray<NSString *> *m_sectionArray; // 分组数据
    NSMutableArray<NSNumber *> *m_stateArray;   // 组展开或折叠状态
    UIImage *m_foldIcon;    // 折叠指示图标
    UIImage *m_unFoldIcon;  // 展开指示图标
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"SYPlayView";
    [self initDataSource];
    
    [self initTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"-------- ViewController dealloc --------");
}

- (void)initDataSource
{
    m_sectionArray  = [NSMutableArray arrayWithObjects:@"YUV", @"RGB", nil];
    NSArray *YUV    = @[@"I420", @"NV12", @"NV21"];
    NSArray *RGB    = @[@"RGB24"];
    m_dataSource    = [NSMutableArray arrayWithObjects:YUV, RGB, nil];
    m_stateArray    = [NSMutableArray arrayWithCapacity:m_dataSource.count];
    m_foldIcon      = [UIImage imageNamed:@"FoldIcon"];
    m_unFoldIcon    = [UIImage imageNamed:@"UnFoldIcon"];
    
    for (int i = 0; i < m_dataSource.count; i++)
    {
        [m_stateArray addObject:@(0)];  // 默认所有折叠
    }
}

- (void)initTableView
{
    self.tableView.rowHeight           = CELL_HEIGHT;
    self.tableView.sectionHeaderHeight = CELL_HEIGHT;
    self.tableView.sectionFooterHeight = CELL_HEIGHT;
    self.tableView.tableFooterView     = [[UIView alloc] initWithFrame:CGRectZero];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - TableView m_dataSource and Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return m_dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (1 == [m_stateArray[section] intValue])    // 展开状态
    {
        NSArray *array = [m_dataSource objectAtIndex:section];
        return array.count;
    }
    else    // 折叠状态
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"SYPlayViewExampleCell";
    UITableViewCell *cell   = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellId];
    }
    NSUInteger sectionIndex      = indexPath.section;
    NSUInteger rowIndex          = indexPath.row;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.text          = m_dataSource[sectionIndex][rowIndex];
    cell.backgroundColor         = [UIColor whiteColor];
    cell.selectionStyle          = UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // 用 button 形象展示 cell 效果
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame     = CGRectMake(0, 0, self.view.frame.size.width, CELL_HEIGHT);
    button.tag       = section + 1;
    button.opaque    = YES;
    button.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.7];
    [button setTitle:m_sectionArray[section]
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor]
                 forState:UIControlStateNormal];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [button addTarget:self
               action:@selector(sectionBtnAction:)
     forControlEvents:UIControlEventTouchUpInside];
    
    // 分割线
    CGRect lineRect      = CGRectMake(0, button.bounds.size.height - 1, button.bounds.size.width, 1);
    UIView *separateLine = [[UIView alloc] initWithFrame:lineRect];
    separateLine.opaque  = YES;
    separateLine.backgroundColor = [UIColor lightGrayColor];
    [button addSubview:separateLine];
    
    // 状态指示图标
    CGRect stateIconRect   = CGRectMake(self.view.frame.size.width - 30, (CELL_HEIGHT-6) * 0.5, 10, 6);
    UIImageView *stateIcon = [[UIImageView alloc] initWithFrame:stateIconRect];
    if (0 == [m_stateArray[section] integerValue])    // 折叠
    {
        stateIcon.image = m_foldIcon;
    }
    else if (1 == [m_stateArray[section] integerValue])   // 展开
    {
        stateIcon.image = m_unFoldIcon;
    }
    [button addSubview:stateIcon];
    
    return button;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSUInteger sectionIndex = indexPath.section;
    NSUInteger rowIndex     = indexPath.row;
    if (0 == sectionIndex)
    {
        if (0 == rowIndex)
        {
            I420ViewController *i420VC = [[I420ViewController alloc] init];
            [self.navigationController pushViewController:i420VC
                                                 animated:YES];
        }
        else if (1 == rowIndex)
        {
            NV12ViewController *nv12VC = [[NV12ViewController alloc] init];
            [self.navigationController pushViewController:nv12VC
                                                 animated:YES];
        }
        else if (2 == rowIndex)
        {
            NV21ViewController *nv21VC = [[NV21ViewController alloc] init];
            [self.navigationController pushViewController:nv21VC
                                                 animated:YES];
        }
        else
        {
            
        }
    }
    else if (1 == sectionIndex)
    {
        if (0 == rowIndex)
        {
            RGB24ViewController *rgb24VC = [[RGB24ViewController alloc] init];
            [self.navigationController pushViewController:rgb24VC
                                                 animated:YES];
        }
        else
        {
            
        }
    }
    else
    {
        
    }
}

#pragma mark -- 展开/折叠操作
- (void)sectionBtnAction:(UIButton *)sender
{
    NSUInteger sectionIndex = sender.tag - 1;
    if (1 == [m_stateArray[sectionIndex] integerValue])
    {
        [m_stateArray replaceObjectAtIndex:sectionIndex
                              withObject:@(0)];
    }
    else
    {
        [m_stateArray replaceObjectAtIndex:sectionIndex
                              withObject:@(1)];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

@end
