//
//  SelectCityViewController.m
//  CustomerOrder
//
//  Created by ios on 13-7-9.
//  Copyright (c) 2013年 hxhd. All rights reserved.
//

#import "SelectCityViewController.h"
#import "CityName.h"
#import "SetColor.h"
#import "ChineseToPinyin.h"
#import "WaitingView.h"

@interface SelectCityViewController ()

@end

@implementation SelectCityViewController
@synthesize cityTableView = _cityTableView;
@synthesize searchBar = _searchBar;
@synthesize mArray = _mArray;
@synthesize kArray = _kArray;
@synthesize mData = _mData;
@synthesize selectCity = _selectCity;
@synthesize cityKeys = _cityKeys;
@synthesize cityList = _cityList;
@synthesize searchResult = _searchResult;
@synthesize cityName = _cityName;

-(void)dealloc
{
    [_cityTableView release];
    [_searchBar release];
    [_mArray release];
    [_mData release];
    [_selectCity release];
    [_cityKeys release];
    [_cityList release];
    [_kArray release];
    [_searchResult release];
    [_cityName release];
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"城市列表";
    
    //自定义导航栏背景颜色
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NaviBg.png"] forBarMetrics:UIBarMetricsDefault];
    
    //右边按钮    
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonSystemItemSave target:self action:@selector(backRight)];
    rightBtn.tintColor = [UIColor orangeColor];
    self.navigationItem.rightBarButtonItem = rightBtn;
    [rightBtn release];
    
    
    // 添加搜索栏
    _searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"请输入城市名字";
    _searchBar.keyboardType = UIKeyboardTypeDefault;
    _searchBar.showsCancelButton = YES;
    _searchBar.showsBookmarkButton = YES;
    _searchBar.translucent = YES;
    _searchBar.barStyle = UIBarStyleBlackTranslucent;
    _searchBar.tintColor = [UIColor orangeColor];
//    _searchBar.prompt = @"搜索"; //提示搜索
    
    [_searchBar sizeToFit];
    [self.view addSubview:_searchBar];

    
    //创建表格
    _cityTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, WIDTH, HEIGHT - 20 - 44 - 49) style:UITableViewStylePlain];
    _cityTableView.dataSource = self;
    _cityTableView.delegate = self;
    [self.view addSubview:_cityTableView];
    
    
    //开始解析
    [self JSONParser];

    
    //等待指示页面
    waitingView = [[WaitingView alloc]initWithFrame:CGRectMake(0, 44, 320, HEIGHT-44-44-20)];
    [self.view addSubview:waitingView];
    [waitingView release];
    [waitingView startWaiting];
}

//返回按钮
- (void)backRight
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//JSON 解析
- (void)JSONParser
{
    NSString *urlStr = [NSString stringWithFormat:CITY_LIST_API];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [request setHTTPMethod:@"POST"];
//    NSString *str = @"op=getProvince";
    NSData *data = [CITY_LIST_ARGUMENT dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark -- NSURLConnectionDataDelegate Method

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.mArray = [[NSMutableArray alloc]init];
    self.kArray = [[NSMutableArray alloc]init];
    self.mData = [[NSMutableData alloc]init];
    
    self.cityName = [[NSMutableArray alloc]init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.mData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSArray *array = [NSJSONSerialization JSONObjectWithData:self.mData options:NSJSONReadingMutableContainers error:nil];
    
    for (NSDictionary *dic in array) {
        
        CityName *cityName = [[[CityName alloc]init]autorelease];
        //model
        cityName.py = [dic objectForKey:@"py"];
        cityName.name = [dic objectForKey:@"name"];
        cityName.cityid = [dic objectForKey:@"id"];
        
        
        NSMutableString *cityInfo = [NSMutableString string];
        //字符串
        [cityInfo appendString:cityName.name];
        [cityInfo appendString:@"/"];
        [cityInfo appendString:cityName.cityid];
       
        
        //存放城市信息字符窜
        [self.mArray addObject:cityInfo];
        
        //存放城市model
        [self.cityName addObject:cityName];
    }
    
    //
    for (int i = 0; i < self.mArray.count; i++) {
        int min = i;
        for (int j = i + 1; j < self.mArray.count; j++) {
            NSString *minCityName = [self.mArray objectAtIndex:min];
            NSString *minCityPinYin = [ChineseToPinyin pinyinFromChiniseString:minCityName];
            NSString *minFirstWord = [minCityPinYin substringToIndex:1];
            
            NSString *cityName = [self.mArray objectAtIndex:j];
            NSString *cityPinYin = [ChineseToPinyin pinyinFromChiniseString:cityName];
            NSString *firstWord = [cityPinYin substringToIndex:1];
            
            NSComparisonResult result = [minFirstWord compare:firstWord];
            if (result == NSOrderedDescending){
                min = j;
            }
        }
        if (min != i) {
            NSString *minCity = [self.mArray objectAtIndex:min];
            [self.mArray replaceObjectAtIndex:min withObject:[self.mArray objectAtIndex:i]];
            [self.mArray replaceObjectAtIndex:i withObject:minCity];
        }
    }

    
    //初始化索引集合和cityList字典
    self.cityKeys = [NSMutableOrderedSet orderedSet];
    self.cityList = [NSMutableDictionary dictionary];
    //初始化搜索结果数组
    self.searchResult = [[NSMutableArray alloc]init];
   
    
    //获取JSON列表数据
    for (int i = 0; i < self.mArray.count; i++) {
        NSString *cityName = [self.mArray objectAtIndex:i];
        NSString *cityPinYin = [ChineseToPinyin pinyinFromChiniseString:cityName];
        NSString *firstWord = [cityPinYin substringToIndex:1];
        [self.cityKeys addObject:firstWord];
        
        NSMutableArray *cityNames = [self.cityList objectForKey:firstWord];
        if (!cityNames) {
            
            cityNames = [NSMutableArray array];
            [self.cityList setObject:cityNames forKey:firstWord];
        }
        [cityNames addObject:cityName];
    }

    //重新载入数据
    [_cityTableView reloadData];
    
    //移除等待页面
    [waitingView stopWaiting];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@",[error localizedDescription]);
}


#pragma mark -- tableView data source 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchResult.count > 0) {
        
        return 1;
        
    } else {
        
    return  self.cityKeys.count;
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchResult.count > 0) {
        
        return [self.searchResult count];
        
    } else {
        
     return [[self.cityList objectForKey:[self.cityKeys objectAtIndex:section]] count];
        
    }
}

#pragma mark -- tableView delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    }
    
    if (self.searchResult.count > 0) {
        
        CityName *sCityName = [self.searchResult objectAtIndex:indexPath.row];
        cell.textLabel.text = sCityName.name;
        
    } else {
    
    NSString  *cityName = [[self.cityList objectForKey:[self.cityKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    //截取城市名字
    NSString *str_intercepted = [cityName substringFromIndex:0];
    NSString *str_character = @"/";
    NSRange range = [str_intercepted rangeOfString:str_character];
    NSString *subCityName = [str_intercepted substringToIndex:range.location];
    cell.textLabel.text = subCityName;

    }
    
    //设置cell被点击之后的背景颜色
    SetColor *cellBG = [SetColor shareInstance];
    [cellBG setCellBackgroundColor:cell];
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchResult.count > 0) {
        
        NSMutableString *mStr = [[[NSMutableString alloc]init]autorelease];
        CityName *sCityName = [self.searchResult objectAtIndex:indexPath.row];
        
        [mStr appendString:sCityName.name];
        [mStr appendString:@"/"];
        [mStr appendString:sCityName.cityid];
        
        self.selectCity = mStr;
     
    } else {
        
        self.selectCity = [[self.cityList objectForKey:[self.cityKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    
    
    if (self.selectCity) {
        
        NSDictionary *city = [NSDictionary dictionaryWithObject:self.selectCity forKey:@"city"];
        NSNotification *notification = [NSNotification notificationWithName:@"SelectCityNotification" object:self userInfo:city];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

//设置每部分标题
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchResult.count > 0) {
        
        return 0;
        
    } else {
        
    return [self.cityKeys objectAtIndex:section];
        
    }
}

//添加右侧索引
-  (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.searchResult.count > 0) {
        
        return 0;
        
    } else {
        
    return [self.cityKeys array];
        
    }
}


#pragma mark -- searchBar delegate  
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [_searchBar resignFirstResponder];
    
    for (CityName * data in self.cityName) {
        
        if ([data.py hasPrefix:searchBar.text]) {
            
            [self.searchResult addObject:data];
        }
    }

    [self.cityTableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"改变 %@",searchText);
    
//    [self.searchResult removeAllObjects];
//    for (int i = 0; i < self.mArray.count; i++) {
//        NSString *cityPinYin = [ChineseToPinyin pinyinFromChiniseString:[self.mArray objectAtIndex:i]];
//        if ([cityPinYin hasPrefix:searchText]||[[cityPinYin lowercaseString] hasPrefix:searchText]) {
//            [self.searchResult addObject:[self.mArray objectAtIndex:i]];
//        }
//    }
//    [self.cityTableView reloadData];
    
    
    if (searchText.length == 0) {
        
        return;
    }
    
    [self.searchResult removeAllObjects];
    
    for (CityName * name in self.cityName) {
        
        if ([name.py hasPrefix:searchText]) {
            
            [self.searchResult addObject:name];
        }
    }
    
    [self.cityTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"取消");
    searchBar.text = @"";
    [_searchBar resignFirstResponder];
    
}


#pragma mark -- scrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_searchBar resignFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
