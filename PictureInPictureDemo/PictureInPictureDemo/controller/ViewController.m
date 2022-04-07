//
//  ViewController.m
//  PictureInPictureDemo
//
//  Created by eye on 3/11/22.
//

#import "ViewController.h"
#import "SoureModel.h"
#import "PlayViewController.h"

@interface ViewController () <UITableViewDataSource,UITableViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray <SoureModel *> *dataList;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    // avplayer
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-mp4-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/1.mp4" isEncrypt:NO playerType:PlayerTypeAvPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-m3u8-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/big_buck_bunny/index.m3u8" isEncrypt:NO playerType:PlayerTypeAvPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-webm-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/webm/3.webm" isEncrypt:NO playerType:PlayerTypeAvPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-mp4-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/1.mp4" isEncrypt:YES playerType:PlayerTypeAvPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-m3u8-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/big_buck_bunny/index.m3u8" isEncrypt:YES playerType:PlayerTypeAvPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"avplayer-webm-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/webm/3.webm" isEncrypt:YES playerType:PlayerTypeAvPlayer]];
    // ijkplayer
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-mp4-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/1.mp4" isEncrypt:NO playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-m3u8-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/big_buck_bunny/index.m3u8" isEncrypt:NO playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-webm-未加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/webm/3.webm" isEncrypt:NO playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-mp4-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/1.mp4" isEncrypt:YES playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-m3u8-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/big_buck_bunny/index.m3u8" isEncrypt:YES playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-webm-加密" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/encryptVideo/webm/3.webm" isEncrypt:YES playerType:PlayerTypeIJKPlayer]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-webm-不加密-bundle文件" url:@"countdown.webm" isEncrypt:NO playerType:PlayerTypeIJKPlayer serverType:ServerTypeLocalBundle]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-webm-不加密-沙盒文件" url:@"3.webm" isEncrypt:NO playerType:PlayerTypeIJKPlayer serverType:ServerTypeLocalSandBox]];
    [self.dataList addObject:[SoureModel modelWithTitle:@"ijkplayer-webm-不加密-远程文件" url:@"https://raw.githubusercontent.com/eye1234456/PictureInPictureDemo/main/video/originVideo/webm/3.webm" isEncrypt:NO playerType:PlayerTypeIJKPlayer serverType:ServerTypeRemote]];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    SoureModel *model = self.dataList[indexPath.row];
    cell.textLabel.text = model.title;
    cell.detailTextLabel.text = model.url;
    cell.detailTextLabel.numberOfLines = 0;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SoureModel *model = self.dataList[indexPath.row];
    PlayViewController *vc = [PlayViewController new];
    vc.model = model;
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark - getter
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"UITableViewCell"];
    }
    return _tableView;
}
- (NSMutableArray *)dataList {
    if (_dataList == nil) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}
@end
